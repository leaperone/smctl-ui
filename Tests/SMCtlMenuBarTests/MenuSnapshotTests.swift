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

    #expect(
        MenuSnapshot.from(ping: ping, battery: battery)
            == .connected(pingLine: "smctld ok 0.2.3", battery: BatterySnapshot.from(battery))
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
        MenuSnapshot.from(ping: ping, battery: battery)
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
    let snapshot = MenuSnapshot.from(ping: ping, battery: battery)

    guard case .connected(_, let live) = snapshot else {
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
    let connected = MenuSnapshot.from(ping: ping, battery: battery)
    let failed = connected.attachingWriteError("Write requests require root or an admin user.")

    guard case .connected(_, let live) = failed else {
        Issue.record("expected connected snapshot with write error")
        return
    }
    #expect(live.lastWriteError == "Write requests require root or an admin user.")
    #expect(live.chargeLine == "Battery 80% · plugged in")
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
