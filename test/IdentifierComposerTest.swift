import PureSwiftUnit
@testable import Parser

class IdentifierComposerTest : TestUnit {
    private var c: IdentifierComposer!

    init() {
        super.init("IdentifierComposer class")
        setTestCases([
            ("can analyze normal identifier", analyzeNormalIdentifier),
            ("can analyze quoted identifier", analyzeQuotedIdentifier),
            ("can analyze implicit parameter", analyzeImplicitParameter)
        ])
    }

    override func beforeCase() {
        c = IdentifierComposer()
    }

    private func analyzeNormalIdentifier() throws {
        try isTrue("put first character", c.put(.IdentifierHead, "i"))
        try isTrue("put second character", c.put(.IdentifierHead, "d"))
        try isNotNil("composed result", c.compose(.IdentifierHead))
    }

    private func analyzeQuotedIdentifier() throws {
        try isTrue("put back quote", c.put(.BackQuote, "`"))
        try isTrue("put first character", c.put(.IdentifierHead, "i"))
        try isTrue("put back quote", c.put(.BackQuote, "`"))
        try isNotNil("composed result", c.compose(.IdentifierHead))
    }

    private func analyzeImplicitParameter() throws {
        try isTrue("put dollar", c.put(.Dollar, "$"))
        try isTrue("put first character", c.put(.Digit, "0"))
        try isNotNil("composed result", c.compose(.IdentifierHead))
    }
}
