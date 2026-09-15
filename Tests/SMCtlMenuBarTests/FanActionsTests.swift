import Testing
@testable import SMCtlMenuBar

@Test(arguments: [
    (FanProfileChoice.auto, "auto"),
    (FanProfileChoice.quiet, "quiet"),
    (FanProfileChoice.full, "full"),
])
func fanProfileMapsToExactSetFanProfileName(choice: FanProfileChoice, expected: String) {
    #expect(choice.wireName == expected)
}

@Test(arguments: [
    ("auto", FanProfileChoice.auto),
    ("quiet", FanProfileChoice.quiet),
    ("full", FanProfileChoice.full),
    (" Quiet ", FanProfileChoice.quiet),
])
func fanProfileMatchesStatusName(profile: String, expected: FanProfileChoice) {
    #expect(FanProfileChoice.matching(profile: profile) == expected)
}

@Test
func returnToAutoIsNotAProfileWrite() {
    #expect(FanCommand.returnToAuto != FanCommand.setProfile(.auto))
}

@Test
func menuChoicesMapToFanCommands() {
    #expect(FanProfileChoice.auto.command == .setProfile(.auto))
    #expect(FanProfileChoice.quiet.command == .setProfile(.quiet))
    #expect(FanProfileChoice.full.command == .setProfile(.full))
}

@Test
func unknownFanProfileDoesNotMatchMenuChoice() {
    #expect(FanProfileChoice.matching(profile: "manual") == nil)
    #expect(FanProfileChoice.matching(profile: "custom-curve") == nil)
}
