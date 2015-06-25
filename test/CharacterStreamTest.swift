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

    private func canReadFile() throws {
        guard let cs = CharacterStream(fp) else {
            throw FailureReason.Text("Could not instantiate with provided file pointer.")
        }
        guard let c = cs.look() else {
            throw FailureReason.Text("Came across to the end of file.")
        }
        try equals("read character", c, "t")
    }
}
