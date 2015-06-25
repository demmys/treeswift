import PureSwiftUnit
@testable import Parser

class IntegerLiteralComposerTest : TestUnit {
    private var c: IntegerLiteralComposer!

    init() {
        super.init("IntegerLiteralComposer class")
        setTestCases([
            ("can analyze decimal digit", analyzeDecimalDigit),
            ("can analyze decimal digit start with zero", analyzeDecimalDigitStartWithZero),
            ("can analyze binary digit", analyzeBinaryDigit),
            ("can analyze octal digit", analyzeOctalDigit),
            ("can analyze hexadecimal digit", analyzeHexadecimalDigit),
            ("can analyze underscore separated digit", analyzeUnderscoreSeparatedDigit)
        ])
    }

    override func beforeCase() {
        c = IntegerLiteralComposer()
    }

    private func analyzeDecimalDigit() throws {
        try isTrue("put first digit", c.put(.Digit, "1"))
        try isTrue("put second digit", c.put(.Digit, "2"))
        try isNotNil("composed result", c.compose(.Digit))
    }

    private func analyzeDecimalDigitStartWithZero() throws {
        try isTrue("put zero", c.put(.Digit, "0"))
        try isTrue("put first digit", c.put(.Digit, "1"))
        try isTrue("put second digit", c.put(.Digit, "2"))
        try isNotNil("composed result", c.compose(.Digit))
    }

    private func analyzeBinaryDigit() throws {
        try isTrue("put zero", c.put(.Digit, "0"))
        try isTrue("put base specifier", c.put(.IdentifierHead, "b"))
        try isTrue("put first digit", c.put(.Digit, "1"))
        try isTrue("put second digit", c.put(.Digit, "0"))
        try isNotNil("composed result", c.compose(.Digit))
    }

    private func analyzeOctalDigit() throws {
        try isTrue("put zero", c.put(.Digit, "0"))
        try isTrue("put base specifier", c.put(.IdentifierHead, "o"))
        try isTrue("put first digit", c.put(.Digit, "7"))
        try isTrue("put second digit", c.put(.Digit, "0"))
        try isNotNil("composed result", c.compose(.Digit))
    }

    private func analyzeHexadecimalDigit() throws {
        try isTrue("put zero", c.put(.Digit, "0"))
        try isTrue("put base specifier", c.put(.IdentifierHead, "x"))
        try isTrue("put first digit", c.put(.Digit, "f"))
        try isTrue("put second digit", c.put(.Digit, "0"))
        try isNotNil("composed result", c.compose(.Digit))
    }

    private func analyzeUnderscoreSeparatedDigit() throws {
        try isTrue("put first digit", c.put(.Digit, "1"))
        try isTrue("put separator", c.put(.Digit, "_"))
        try isTrue("put second digit", c.put(.Digit, "2"))
        try isNotNil("composed result", c.compose(.Digit))
    }
}
