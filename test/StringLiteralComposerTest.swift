import PureSwiftUnit
@testable import Parser

class StringLiteralComposerTest : TokenComposerTest {
    init() {
        super.init("StringLiteralComposer class can", { StringLiteralComposer() })
        setTestCases([
            ("analyze string literal", analyzeStringLiteral),
            ("analyze escaped characters", analyzeEscapedCharacters),
            ("can analyze empty string", analyzeEmptyString),
            ("not analyze unescaped line feed", notAnalyzeUnescapedLineFeed),
            ("not analyze unescaped carriage return", notAnalyzeUnescapedCarriageReturn),
        ])
    }

    private func isStringLiteral(literal: String, _ expected: String) throws {
        switch try putStringAndCompose(literal) {
        case let .StringLiteral(s):
            try equals("parsed string", s, expected)
        default:
            throw FailureReason.Text("expected composed result to StringLiteral but actual is not StringLiteral.")
        }
    }

    private func analyzeStringLiteral() throws {
        try isStringLiteral("\"string\"", "string")
    }

    private func analyzeEscapedCharacters() throws {
        try isStringLiteral("\"\\0, \\\\, \\t, \\n, \\r, \\\", \\', \\u{1f363}\"", "\0, \\, \t, \n, \r, \", \', \u{1f363}")
    }

    private func analyzeEmptyString() throws {
        try isStringLiteral("\"\"", "")
    }

    private func notAnalyzeUnescapedLineFeed() throws {
        try putString("\"")
        try putFail("\n")
    }

    private func notAnalyzeUnescapedCarriageReturn() throws {
        try putString("\"")
        try putFail("\r")
    }
}
