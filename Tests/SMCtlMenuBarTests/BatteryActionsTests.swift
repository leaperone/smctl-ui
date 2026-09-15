import Testing
@testable import SMCtlMenuBar

@Test(arguments: [
    (MaintainPreset.cap80, "80"),
    (MaintainPreset.band7080, "70-80"),
    (MaintainPreset.stop, "100"),
])
func maintainPresetMapsToExactLimitString(preset: MaintainPreset, expected: String) {
    #expect(preset.wireLimit == expected)
}

@Test(arguments: [
    ("100", MaintainPreset.stop),
    ("stop", MaintainPreset.stop),
    ("off", MaintainPreset.stop),
    ("disabled", MaintainPreset.stop),
    ("80", MaintainPreset.cap80),
    ("70-80", MaintainPreset.band7080),
])
func maintainPresetMatchesConfiguredLimit(configured: String, expected: MaintainPreset) {
    #expect(MaintainPreset.matching(configuredLimit: configured) == expected)
}

@Test(arguments: [
    (49, 50),
    (50, 50),
    (80, 80),
    (100, 100),
    (101, 100),
])
func chargeLimitCapClampsToLegalRange(raw: Int, expected: Int) {
    #expect(ChargeLimitCap(clamping: raw).value == expected)
}

@Test(arguments: [
    (72, "72"),
    (40, "50"),
    (100, "100"),
    (110, "100"),
])
func setCapWiresClampedDecimalString(raw: Int, expected: String) {
    #expect(BatteryCommand.setCap(raw).wireLimit == expected)
    #expect(ChargeLimitCap(clamping: raw).wireLimit == expected)
}

@Test
func setCapAtFullMatchesStopWireLimit() {
    #expect(BatteryCommand.setCap(100).wireLimit == MaintainPreset.stop.wireLimit)
    #expect(ChargeLimitCap(clamping: 100).isFull)
}
