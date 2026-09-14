import Foundation
import Testing
#if canImport(SMCtlProtocol)
import SMCtlProtocol
#endif
@testable import SMCtlMenuBar

@Test
func connectedSnapshotFromFakePingDTO() {
    let ping = PingDTO(
        ok: true,
        version: "0.2.3",
        timestamp: Date(timeIntervalSince1970: 1_700_000_000)
    )
    let battery = sampleBattery(percent: 80, charging: true, pluggedIn: true, limit: "80")

    let fans = sampleFans()

    #expect(
        MenuSnapshot.from(ping: ping, battery: battery, fans: fans)
            == .connected(
                pingLine: "smctld ok 0.2.3",
                battery: BatterySnapshot.from(battery),
                fans: FanSnapshot.from(fans)
            )
    )
}

@Test
func pluggedInIdleBatteryLine() {
    let battery = BatterySnapshot.from(
        sampleBattery(percent: 64, charging: false, pluggedIn: true, limit: "80")
    )

    #expect(battery.chargeLine == "Battery 64% · plugged in")
    #expect(battery.limitLine == "Limit 80")
    #expect(battery.selectedMaintain == .cap80)
}

@Test
func failedPingIsDisconnected() {
    let ping = PingDTO(ok: false, version: "0.2.3", timestamp: Date(timeIntervalSince1970: 0))
    let battery = sampleBattery(percent: 50, charging: false, pluggedIn: false, limit: "80")

    #expect(
        MenuSnapshot.from(ping: ping, battery: battery, fans: sampleFans())
            == .disconnected(message: "Daemon ping returned not ok")
    )
}

@Test
func errorSnapshotIsDisconnectedWithoutLiveDaemon() {
    struct SampleError: LocalizedError {
        var errorDescription: String? { "smctld is not running" }
    }

    #expect(
        MenuSnapshot.from(error: SampleError())
            == .disconnected(message: "smctld is not running")
    )
}

@Test
func missingChargePercent() {
    let ping = PingDTO(ok: true, version: "0.2.3", timestamp: Date(timeIntervalSince1970: 0))
    let battery = sampleBattery(percent: nil, charging: nil, pluggedIn: nil, limit: "80")
    let snapshot = MenuSnapshot.from(ping: ping, battery: battery, fans: sampleFans())

    guard case .connected(_, let live, _) = snapshot else {
        Issue.record("expected connected snapshot")
        return
    }
    #expect(live.chargeLine == "Battery unavailable")
}

@Test
func maintainBandAndStopDisplay() {
    let band = BatterySnapshot.from(
        sampleBattery(percent: 75, charging: false, pluggedIn: true, limit: "70-80")
    )
    let stopped = BatterySnapshot.from(
        sampleBattery(percent: 90, charging: true, pluggedIn: true, limit: "100")
    )
    let unknown = BatterySnapshot.from(
        sampleBattery(percent: 50, charging: false, pluggedIn: false, limit: "60")
    )

    #expect(band.limitLine == "Limit 70-80")
    #expect(band.selectedMaintain == .band7080)
    #expect(stopped.limitLine == "Limit off")
    #expect(stopped.selectedMaintain == .stop)
    #expect(unknown.selectedMaintain == nil)
}

@Test
func writeErrorStaysOnConnectedSnapshot() {
    let ping = PingDTO(ok: true, version: "0.2.3", timestamp: Date(timeIntervalSince1970: 0))
    let battery = sampleBattery(percent: 80, charging: false, pluggedIn: true, limit: "80")
    let connected = MenuSnapshot.from(ping: ping, battery: battery, fans: sampleFans())
    let failed = connected.attachingWriteError("Write requests require root or an admin user.")

    guard case .connected(_, let live, _) = failed else {
        Issue.record("expected connected snapshot with write error")
        return
    }
    #expect(live.lastWriteError == "Write requests require root or an admin user.")
    #expect(live.chargeLine == "Battery 80% · plugged in")
}

@Test
func emptyFansUsesDaemonMessage() {
    let fans = FanSnapshot.from(sampleFans())

    #expect(fans.profileLine == "Profile auto")
    #expect(fans.emptyLine == "No fans were reported by SMC.")
    #expect(fans.rows.isEmpty)
    #expect(fans.selectedProfile == .auto)
    #expect(FanSnapshot.thermalGuardLine == "Thermal guard remains active.")
}

@Test
func fanRPMRowsAndSelectedProfile() {
    let fans = FanSnapshot.from(
        sampleFans(
            profile: "quiet",
            fans: [
                FanStatusDTO(
                    index: 0,
                    actualRPM: 1843,
                    targetRPM: 2000,
                    minimumRPM: 800,
                    maximumRPM: 6000,
                    mode: "manual"
                )
            ],
            message: nil
        )
    )

    #expect(fans.profileLine == "Profile quiet")
    #expect(fans.rows.map(\.line) == ["Fan 0 · 1843 RPM"])
    #expect(fans.selectedProfile == .quiet)
    #expect(fans.emptyLine == "No fans were reported by SMC.")
    #expect(FanSnapshot.thermalGuardLine == "Thermal guard remains active.")
}

@Test
func unknownFanProfileHasNoMenuSelection() {
    let fans = FanSnapshot.from(sampleFans(profile: "manual", message: nil))
    #expect(fans.selectedProfile == nil)
    #expect(fans.profileLine == "Profile manual")
}

@Test
func fanWriteErrorStaysOnConnectedSnapshot() {
    let ping = PingDTO(ok: true, version: "0.2.3", timestamp: Date(timeIntervalSince1970: 0))
    let battery = sampleBattery(percent: 80, charging: false, pluggedIn: true, limit: "80")
    let connected = MenuSnapshot.from(ping: ping, battery: battery, fans: sampleFans())
    let failed = connected.attachingFanWriteError("No writable fan mode keys were detected on this Mac/system.")

    guard case .connected(_, _, let live) = failed else {
        Issue.record("expected connected snapshot with fan write error")
        return
    }
    #expect(live.lastWriteError == "No writable fan mode keys were detected on this Mac/system.")
    #expect(live.profileLine == "Profile auto")
}

private func sampleBattery(
    percent: Int?,
    charging: Bool?,
    pluggedIn: Bool?,
    limit: String
) -> BatteryStatusDTO {
    BatteryStatusDTO(
        timestamp: Date(timeIntervalSince1970: 0),
        chargePercent: percent,
        isCharging: charging,
        pluggedIn: pluggedIn,
        chargingControlSupported: true,
        adapterControlSupported: true,
        chargingControlGroup: nil,
        adapterControlGroup: nil,
        configuredLimit: limit,
        lowerBound: 70,
        upperBound: 80,
        sleepPolicy: "ignore",
        message: nil
    )
}

private func sampleFans(
    profile: String = "auto",
    fans: [FanStatusDTO] = [],
    message: String? = "No fans were reported by SMC."
) -> FansStatusDTO {
    FansStatusDTO(
        timestamp: Date(timeIntervalSince1970: 0),
        profile: profile,
        fans: fans,
        message: message
    )
}
