import PureSwiftUnit
@testable import Parser

class ParserTest : TestUnit {
    init() {
        super.init("Parser class")
        setTestCases([
            ("can not parse inexistent file", inexistentFile)
        ])
    }

    private func inexistentFile() throws {
        let parser = Parser(["inexistentfile"])
        do {
            try parser.parse()
            throw FailureReason.Text("Parser could parse.")
        } catch _ {}
    }
}
