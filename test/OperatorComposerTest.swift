import PureSwiftUnit
@testable import Parser

class OperatorComposerTest : TestUnit {
    private var c: OperatorComposer!

    init() {
        super.init("OperatorComposer class")
        setTestCases([
            ("can analyze operator", analyzeOperator),
            ("can analyze dot operator", analyzeDotOperator),
            ("can analyze reserved operator", analyzeReservedOperator)
        ])
    }

    override func beforeCase() {
        c = OperatorComposer(prev: .LeftParenthesis)
    }

    private func analyzeOperator() throws {
        try isTrue("put first operator character", c.put(.OperatorHead, "+"))
        try isTrue("put second operator character", c.put(.OperatorHead, "+"))
        try isNotNil("composed result", c.compose(.RightParenthesis))
    }

    private func analyzeDotOperator() throws {
        try isTrue("put dot", c.put(.DotOperatorHead, "."))
        try isTrue("put following dot", c.put(.Dot, "."))
        try isTrue("put operator character", c.put(.Dot, "+"))
        try isNotNil("composed result", c.compose(.RightParenthesis))
    }

    private func analyzeReservedOperator() throws {
        try isTrue("put reserved operator", c.put(.Question, "?"))
        try isNotNil("composed result", c.compose(.RightParenthesis))
    }
}
