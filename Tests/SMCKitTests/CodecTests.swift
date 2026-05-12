import Testing
import Foundation
@testable import SMCKit

@Test func fpe2_roundtrip() throws {
    let v = SMCValue.encodeFPE2(2456)
    #expect(v.type == SMCType.fpe2)
    let decoded = try v.decodeAsDouble()
    #expect(Int(decoded) == 2456)
}

@Test func fpe2_zero() throws {
    let v = SMCValue.encodeFPE2(0)
    #expect(try v.decodeAsDouble() == 0)
}

@Test func ui8_decode() throws {
    let v = SMCValue.encodeUI8(7)
    #expect(v.type == SMCType.ui8)
    #expect(try v.decodeAsDouble() == 7)
}

@Test func smcKey_fourCC_roundtrip() {
    let k = SMCKey("FNum")
    #expect(k.description == "FNum")
}

@Test func smcKey_fanIndexed() {
    #expect(SMCKey("F0Ac").description == "F0Ac")
    #expect(SMCKey("F1Mx").description == "F1Mx")
}
