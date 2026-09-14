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
