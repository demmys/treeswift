import PureSwiftUnit
@testable import Parser

class ParserTest : TestUnit {
    var description: String {
        get { return "Parser class" }
    }

    var testCases: [TestCase] { get { return [
        TestCase(self,
                 test: inexistentFile, 
                 description: "can not parse inexistent file")
    ] } }

    func setUp() {}

    func beforeCase() {}

    private func inexistentFile() -> TestResult {
        let parser = Parser(["inexistentfile"])
        switch parser.parse() {
        case .TokensOfFiles:
            return .Failure("Parser returns some tokens.")
        case .Error:
            return .Success
        }
    }

    func afterCase() {}

    func tearDown() {}
}
