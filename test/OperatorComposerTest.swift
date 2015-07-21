import PureSwiftUnit
@testable import Parser

class OperatorComposerTest : TokenComposerTest {
    init() {
        super.init("OperatorComposer class", { OperatorComposer(prev: .Space) })
        setTestCases([
            ("can analyze operator", analyzeOperator),
            ("can analyze dot operator", analyzeDotOperator),
            ("can analyze operator start and end with '-'", analyzeOperatorWithMinus)
        ])
    }

    private func isOperator(literal: String, _ expected: String) throws {
        switch try putStringAndCompose(literal) {
        case let .BinaryOperator(s):
            try equals("parsed operator", s, expected)
        default:
            throw FailureReason.Text("expected composed result to BinaryOperator but actual is not BinaryOperator")
        }
    }

    private func analyzeOperator() throws {
        try isOperator("++", "++")
    }

    private func analyzeDotOperator() throws {
        try isOperator("..+", "..+")
    }

    private func analyzeOperatorWithMinus() throws {
        try isOperator("---", "---")
    }
}
