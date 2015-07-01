import PureSwiftUnit
@testable import Parser

class NumericLiteralComposerTest : TestUnit {
    private var nc: NumericLiteralComposer!

    init() {
        super.init("NumericLiteralComposer class can")
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

    override func beforeCase() {
        nc = NumericLiteralComposer()
    }

    private func putStringAndCompose(s: String) throws {
        for var i = s.startIndex; i != s.endIndex; i = i.successor() {
            let c = s[i]
            switch c {
            case "0"..."9":
                try isTrue("put digit \(c)", nc.put(.Digit, c))
            case "a"..."z", "A"..."Z", "p", "P":
                try isTrue("put character \(c)", nc.put(.IdentifierHead, c))
            case "+", "-":
                try isTrue("put symbol \(c)", nc.put(.OperatorHead, c))
            case "_":
                try isTrue("put underscore", nc.put(.IdentifierHead, c))
            case ".":
                try isTrue("put dot", nc.put(.Dot, c))
            default:
                try isTrue("put \(c)", nc.put(.Others, c))
            }
        }
        try isNotNil("composed result", nc.compose(.RightParenthesis))
    }

    private func analyzeInteger() throws {
        try putStringAndCompose("9876")
    }

    private func analyzeIntegerStartWithZero() throws {
        try putStringAndCompose("0123")
    }

    private func analyzeBinaryInteger() throws {
        try putStringAndCompose("0b10")
    }

    private func analyzeOctalInteger() throws {
        try putStringAndCompose("0o7654")
    }

    private func analyzeHexInteger() throws {
        try putStringAndCompose("0xfedc")
    }

    private func analyzeUnderscoreSeparatedInteger() throws {
        try putStringAndCompose("9_87_654")
    }

    private func analyzeDecimalFraction() throws {
        try putStringAndCompose("98.7654")
    }

    private func analyzeDecimalFractionStartWithZero() throws {
        try putStringAndCompose("01.2345")
    }

    private func analyzeHexFraction() throws {
        try putStringAndCompose("0xfe.dcba")
    }

    private func analyzeUnderscoreSeparatedDecimalFraction() throws {
        try putStringAndCompose("9.87_654")
    }

    private func analyzeUnderscoreSeparatedHexFraction() throws {
        try putStringAndCompose("0xf.ed_cba")
    }

    private func analyzeLargeEExponent() throws {
        try putStringAndCompose("98.765E12")
    }

    private func analyzeSmallEExponent() throws {
        try putStringAndCompose("98.765e12")
    }

    private func analyzePositiveExponent() throws {
        try putStringAndCompose("98.765e+12")
    }

    private func analyzeNegativeExponent() throws {
        try putStringAndCompose("98.765e-12")
    }

    private func analyzeLargePHexExponent() throws {
        try putStringAndCompose("0xfe.dcbP12")
    }

    private func analyzeSmallPHexExponent() throws {
        try putStringAndCompose("0xfe.dcbp12")
    }
}
