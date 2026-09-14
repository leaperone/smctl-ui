import XCTest
#if canImport(SMCtlProtocol)
import SMCtlProtocol
#endif
@testable import SMCtlMenuBar

final class MenuSnapshotTests: XCTestCase {
    func testConnectedSnapshotFromFakePingDTO() {
        let ping = PingDTO(
            ok: true,
            version: "0.2.3",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let battery = sampleBattery(percent: 80, charging: true, pluggedIn: true)

        let snapshot = MenuSnapshot.from(ping: ping, battery: battery)

        XCTAssertEqual(
            snapshot,
            .connected(pingLine: "smctld ok 0.2.3", statusLine: "Battery 80% · charging")
        )
    }

    func testPluggedInIdleBatteryLine() {
        let ping = PingDTO(ok: true, version: "0.1.8", timestamp: Date(timeIntervalSince1970: 0))
        let battery = sampleBattery(percent: 64, charging: false, pluggedIn: true)

        let snapshot = MenuSnapshot.from(ping: ping, battery: battery)

        XCTAssertEqual(
            snapshot,
            .connected(pingLine: "smctld ok 0.1.8", statusLine: "Battery 64% · plugged in")
        )
    }

    func testFailedPingIsDisconnected() {
        let ping = PingDTO(ok: false, version: "0.2.3", timestamp: Date(timeIntervalSince1970: 0))
        let battery = sampleBattery(percent: 50, charging: false, pluggedIn: false)

        let snapshot = MenuSnapshot.from(ping: ping, battery: battery)

        XCTAssertEqual(snapshot, .disconnected(message: "Daemon ping returned not ok"))
    }

    func testErrorSnapshotIsDisconnectedWithoutLiveDaemon() {
        let error = NSError(
            domain: "SMCtlMenuBarTests",
            code: 4099,
            userInfo: [NSLocalizedDescriptionKey: "smctld is not running"]
        )

        XCTAssertEqual(
            MenuSnapshot.from(error: error),
            .disconnected(message: "smctld is not running")
        )
    }

    func testMissingChargePercent() {
        let ping = PingDTO(ok: true, version: "0.2.3", timestamp: Date(timeIntervalSince1970: 0))
        let battery = sampleBattery(percent: nil, charging: nil, pluggedIn: nil)

        let snapshot = MenuSnapshot.from(ping: ping, battery: battery)

        XCTAssertEqual(
            snapshot,
            .connected(pingLine: "smctld ok 0.2.3", statusLine: "Battery unavailable")
        )
    }
}

private func sampleBattery(percent: Int?, charging: Bool?, pluggedIn: Bool?) -> BatteryStatusDTO {
    BatteryStatusDTO(
        timestamp: Date(timeIntervalSince1970: 0),
        chargePercent: percent,
        isCharging: charging,
        pluggedIn: pluggedIn,
        chargingControlSupported: true,
        adapterControlSupported: true,
        chargingControlGroup: nil,
        adapterControlGroup: nil,
        configuredLimit: "80",
        lowerBound: 70,
        upperBound: 80,
        sleepPolicy: "ignore",
        message: nil
    )
}
