import PureSwiftUnit
@testable import Parser

class NumericLiteralComposerTest : TokenComposerTest {
    init() {
        super.init("NumericLiteralComposer class can", { NumericLiteralComposer() })
        setTestCases([
            ("analyze decimal integer", analyzeInteger),
            ("analyze decimal integer start with zero", analyzeIntegerStartWithZero),
            ("analyze binary integer", analyzeBinaryInteger),
            ("analyze octal integer", analyzeOctalInteger),
            ("analyze hex integer", analyzeHexInteger),
            ("analyze underscore separated integer", analyzeUnderscoreSeparatedInteger),

            ("analyze decimal exponent specified with 'E'", analyzeLargeEExponent),
            ("analyze decimal exponent specified with 'e'", analyzeSmallEExponent),
            ("analyze positive exponent", analyzePositiveExponent),
            ("analyze negative exponent", analyzeNegativeExponent),

            ("analyze hex exponent specified with 'P'", analyzeLargePHexExponent),
            ("analyze hex exponent specified with 'p'", analyzeSmallPHexExponent),
            ("not analyze exponent with hex exponent part", notAnalyzeExponentHexExponentPart),

            ("analyze decimal fraction", analyzeDecimalFraction),
            ("analyze decimal fraction start with zero", analyzeDecimalFractionStartWithZero),
            ("analyze underscore separated decimal fraction", analyzeUnderscoreSeparatedDecimalFraction),
            ("not analyze hex decimal fraction without exponent", notAnalyzeHexFractionWithoutExponent),
            ("analyze hex fraction with exponent", analyzeHexFractionWithExponent),
            ("analyze negative number", analyzeNegativeNumber)
        ])
    }

    private func isIntegerLiteral(
        literal: String, _ expected: Int64, _ isDecimalDigits: Bool
    ) throws {
        switch try putStringAndCompose(literal) {
        case let .IntegerLiteral(n, decimalDigits: d):
            try equals("isdecimalDigits flag", isDecimalDigits, d)
            try equals("parsed number", expected, n)
        default:
            throw FailureReason.Text("expected composed result to IntegerLiteral but actual is not IntegerLiteral.")
        }
    }

    private func isFloatingPointLiteral(literal: String, _ expected: Double) throws {
        switch try putStringAndCompose(literal) {
        case let .FloatingPointLiteral(r):
            try equals("parsed number", expected, r)
        default:
            throw FailureReason.Text("expected composed result to FloatingPointLiteral but actual is not FloatingPointLiteral.")
        }
    }

    private func analyzeInteger() throws {
        try isIntegerLiteral("9876", 9876, true)
    }

    private func analyzeIntegerStartWithZero() throws {
        try isIntegerLiteral("0123", 0123, true)
    }

    private func analyzeBinaryInteger() throws {
        try isIntegerLiteral("0b10", 0b10, false)
    }

    private func analyzeOctalInteger() throws {
        try isIntegerLiteral("0o7654", 0o7654, false)
    }

    private func analyzeHexInteger() throws {
        try isIntegerLiteral("0xfedc", 0xfedc, false)
    }

    private func analyzeUnderscoreSeparatedInteger() throws {
        try isIntegerLiteral("9_87_654", 9_87_654, true)
    }

    private func analyzeLargeEExponent() throws {
        try isFloatingPointLiteral("98E12", 98E12)
    }

    private func analyzeSmallEExponent() throws {
        try isFloatingPointLiteral("98e12", 98e12)
    }

    private func analyzePositiveExponent() throws {
        try isFloatingPointLiteral("98e+12", 98e+12)
    }

    private func analyzeNegativeExponent() throws {
        try isFloatingPointLiteral("98e-12", 98e-12)
    }

    private func notAnalyzeExponentHexExponentPart() throws {
        try putString("0xfep")
        try putFail("a")
    }

    private func analyzeLargePHexExponent() throws {
        try isFloatingPointLiteral("0xfeP12", 0xfeP12)
    }

    private func analyzeSmallPHexExponent() throws {
        try isFloatingPointLiteral("0xfep12", 0xfep12)
    }

    private func analyzeDecimalFraction() throws {
        try isFloatingPointLiteral("98.7654", 98.7654)
    }

    private func analyzeDecimalFractionStartWithZero() throws {
        try isFloatingPointLiteral("01.2345", 01.2345)
    }

    private func analyzeUnderscoreSeparatedDecimalFraction() throws {
        try isFloatingPointLiteral("9.87_654", 9.87_654)
    }

    private func notAnalyzeHexFractionWithoutExponent() throws {
        try putString("0xfe.dcba")
        try composeNil()
    }

    private func analyzeHexFractionWithExponent() throws {
        try isFloatingPointLiteral("0xfe.dcbap12", 0xfe.dcbap12)
    }

    private func analyzeNegativeNumber() throws {
        try isIntegerLiteral("-123", -123, false)
    }
}
