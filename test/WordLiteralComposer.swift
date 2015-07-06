import PureSwiftUnit
@testable import Parser

class WordLiteralComposerTest : TokenComposerTest {
    init() {
        super.init("WordLiteralComposer class", { WordLiteralComposer("if", .If) })
        setTestCases([
            ("returns false when put a incorrect character", putIncorrectCharacter),
            ("not succeeds if the length of put word exceeds set word length", putExceededLength),
            ("succeeds if whole expected characters are put", putExpectedWord)
        ])
    }

    private func isExpectedToken(literal: String, _ expected: TokenKind) throws {
        try equals("parsed token", expected, try putStringAndCompose(literal))
    }

    private func putIncorrectCharacter() throws {
        try putFail("j")
    }

    private func putExceededLength() throws {
        try putString("if")
        try putFail("g")
    }

    private func putExpectedWord() throws {
        try isExpectedToken("if", .If)
    }
}
