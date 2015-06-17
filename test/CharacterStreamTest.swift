import PureSwiftUnit
import Darwin
import Util
@testable import Parser

class CharacterStreamTest : TestUnit {
    let testFileName = "__testfile"
    var fp: File!

    init() {
        super.init("CharacterStream class")
        setTestCases([
            ("can read character of file", canReadFile)
        ])
    }

    override func setUp() {
        let writer = fopen(testFileName, "w")
        fwrite("test\n", sizeof(CChar), 5, writer)
        fclose(writer)
        fp = File(name: testFileName, mode: "r")
    }

    override func tearDown() {
        remove(testFileName)
    }

    private func canReadFile() -> TestResult {
        if let cs = CharacterStream(fp) {
            if let c = cs.look() {
                if c == "t" {
                    return .Success
                }
                return TestResult.buildFailure(
                    "read character", expected: "t", actual: String(c)
                )
            }
            return .Failure("Came across to the end of file.")
        }
        return .Failure("Could not instantiate with provided file pointer.")
    }
}
