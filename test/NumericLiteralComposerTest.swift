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
            ("analyze decimal fraction", analyzeDecimalFraction),
            ("analyze decimal fraction start with zero", analyzeDecimalFractionStartWithZero),
            ("analyze hex decimal fraction", analyzeHexFraction),
            ("analyze underscore separated decimal fraction", analyzeUnderscoreSeparatedDecimalFraction),
            ("analyze underscore separated hex fraction", analyzeUnderscoreSeparatedHexFraction),
            ("analyze decimal exponent specified with 'E'", analyzeLargeEExponent),
            ("analyze decimal exponent specified with 'e'", analyzeSmallEExponent),
            ("analyze positive exponent", analyzePositiveExponent),
            ("analyze negative exponent", analyzeNegativeExponent),
            ("analyze hex exponent specified with 'P'", analyzeLargePHexExponent),
            ("analyze hex exponent specified with 'p'", analyzeSmallPHexExponent)
        ])
    }

    private func isIntegerLiteral(
        literal: String, _ expected: Int64, _ isDecimalDigits: Bool
    ) throws {
        switch try putStringAndCompose(literal) {
        case let .IntegerLiteral(n, decimalDigits: d):
            try equals("isdecimalDigits flag", d, isDecimalDigits)
            try equals("parsed number", n, expected)
        default:
            throw FailureReason.Text("expected composed result to IntegerLiteral but actual is not IntegerLiteral.")
        }
    }

    private func isFloatingPointLiteral(literal: String, _ expected: Double) throws {
        switch try putStringAndCompose(literal) {
        case let .FloatingPointLiteral(r):
            try equals("parsed number", r, expected)
        default:
            throw FailureReason.Text("expected composed result to FloatingPointLiteral but actual is not FloatingPointLiteral.")
        }
    }

    private func analyzeInteger() throws {
        try isIntegerLiteral("9876", 9876, true)
    }

    private func analyzeIntegerStartWithZero() throws {
        try isIntegerLiteral("0123", 123, true)
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
        try isIntegerLiteral("9_87_654", 987654, true)
    }

    private func analyzeDecimalFraction() throws {
        try isFloatingPointLiteral("98.7654", 98.7654)
    }

    private func analyzeDecimalFractionStartWithZero() throws {
        try isFloatingPointLiteral("01.2345", 1.2345)
    }

    private func analyzeHexFraction() throws {
        try isFloatingPointLiteral("0xfe.dcba", 0xfe.dcbap1)
    }

    private func analyzeUnderscoreSeparatedDecimalFraction() throws {
        try isFloatingPointLiteral("9.87_654", 9.87654)
    }

    private func analyzeUnderscoreSeparatedHexFraction() throws {
        try isFloatingPointLiteral("0xf.ed_cba", 0xf.ed_cbap1)
    }

    private func analyzeLargeEExponent() throws {
        try isFloatingPointLiteral("98.765E12", 98.765e12)
    }

    private func analyzeSmallEExponent() throws {
        try isFloatingPointLiteral("98.765e12", 98.765e12)
    }

    private func analyzePositiveExponent() throws {
        try isFloatingPointLiteral("98.765e+12", 98.765e12)
    }

    private func analyzeNegativeExponent() throws {
        try isFloatingPointLiteral("98.765e-12", 98.765e-12)
    }

    private func analyzeLargePHexExponent() throws {
        try isFloatingPointLiteral("0xfe.dcbP12", 0xfe.dcbp12)
    }

    private func analyzeSmallPHexExponent() throws {
        try isFloatingPointLiteral("0xfe.dcbp12", 0xfe.dcbp12)
    }
}
