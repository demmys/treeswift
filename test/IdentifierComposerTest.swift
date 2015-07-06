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

    private func isIdentifier(literal: String, _ expected: IdentifierKind) throws {
        switch try putStringAndCompose(literal) {
        case let .Identifier(k):
            try equals("parsed identifier", k, expected)
        default:
            throw FailureReason.Text("expected composed result to Identifier but actual is not Identifier.")
        }
    }

    private func analyzeNormalIdentifier() throws {
        try isIdentifier("id", .Identifier("id"))
    }

    private func analyzeQuotedIdentifier() throws {
        try isIdentifier("`if`", .QuotedIdentifier("if"))
    }

    private func analyzeImplicitParameter() throws {
        try isIdentifier("$0", .ImplicitParameter(0))
    }
}
