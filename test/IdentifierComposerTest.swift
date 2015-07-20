import PureSwiftUnit
@testable import Parser

class IdentifierComposerTest : TokenComposerTest {
    init() {
        super.init("IdentifierComposer class can", { IdentifierComposer() })
        setTestCases([
            ("analyze normal identifier", analyzeNormalIdentifier),
            ("analyze quoted identifier", analyzeQuotedIdentifier),
            ("analyze implicit parameter", analyzeImplicitParameter)
        ])
    }

    private func isIdentifier(literal: String, _ expected: String) throws {
        switch try putStringAndCompose(literal) {
        case let .Identifier(s):
            try equals("parsed identifier", s, expected)
        default:
            throw FailureReason.Text("expected composed result to Identifier but actual is not Identifier.")
        }
    }

    private func isImplicitParameterName(literal: String, _ expected: Int) throws {
        switch try putStringAndCompose(literal) {
        case let .ImplicitParameterName(i):
            try equals("parsed implicit parameter name", i, expected)
        default:
            throw FailureReason.Text("expected composed result to ImplicitParameterName but actual is not ImplicitParameterName.")
        }
    }

    private func analyzeNormalIdentifier() throws {
        try isIdentifier("id", "id")
    }

    private func analyzeQuotedIdentifier() throws {
        try isIdentifier("`if`", "if")
    }

    private func analyzeImplicitParameter() throws {
        try isImplicitParameterName("$0", 0)
    }
}
