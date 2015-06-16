import PureSwiftUnit
import Darwin
import Util
@testable import Parser

class CharacterStreamTest : TestUnit {
    let testFileName = "__testfile"
    var fp: File!

    var description: String { get { return "CharacterStream class" } }

    var testCases: [TestCase] { get { return [
        TestCase(self,
                 test: canReadFile,
                 description: "can read character of file")
    ] } }

    func setUp() {
        let writer = fopen(testFileName, "w")
        fwrite("test\n", sizeof(CChar), 5, writer)
        fclose(writer)
        fp = File(name: testFileName, mode: "r")
    }

    func beforeCase() {}

    private func canReadFile() -> TestResult {
        if let cs = CharacterStream(fp) {
            if let c = cs.look() {
                if c == "t" {
                    return .Success
                }
                return TestResult.buildFailure("read character",
                                               expected: "t",
                                               actual: String(c))
            }
            return .Failure("Came across to the end of file.")
        }
        return .Failure("Could not instantiate with provided file pointer.")
    }

    func afterCase() {}

    func tearDown() {
        remove(testFileName)
    }
}
