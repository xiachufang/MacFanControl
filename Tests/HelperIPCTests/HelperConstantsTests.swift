import Testing
@testable import HelperIPC

@Test func helper_identifiers_match_convention() {
    #expect(HelperConstants.helperBundleID == "com.slothease.macfancontrol.helper")
    #expect(HelperConstants.machServiceName == HelperConstants.helperBundleID)
    #expect(HelperConstants.daemonPlistName.hasSuffix(".plist"))
}
