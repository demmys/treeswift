import PureSwiftUnit
@testable import Parser

class ParserTest : TestUnit {
    init() {
        super.init("Parser class")
        setTestCases([
            ("can not parse inexistent file", inexistentFile)
        ])
    }

    private func inexistentFile() -> TestResult {
        let parser = Parser(["inexistentfile"])
        switch parser.parse() {
        case .TokensOfFiles:
            return .Failure("Parser returns some tokens.")
        case .Error:
            return .Success
        }
    }
}
