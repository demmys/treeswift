import PureSwiftUnit
@testable import Parser

class WordLiteralComposerTest : TestUnit {
    private var c: WordLiteralComposer!

    init() {
        super.init("WordLiteralComposer class")
        setTestCases([
            ("returns false when put a incorrect character", putIncorrectCharacter),
            ("not succeeds if the length of put word exceeds set word length", putExceededLength),
            ("succeeds if whole expected characters are put", putExpectedWord)
        ])
    }

    override func beforeCase() {
        c = WordLiteralComposer("if", .If)
    }

    private func putIncorrectCharacter() throws {
        try isFalse("put result", c.put(.IdentifierHead, "j"))
    }

    private func putExceededLength() throws {
        c.put(.IdentifierHead, "i")
        c.put(.IdentifierHead, "f")
        try isFalse("put result", c.put(.IdentifierHead, "g"))
        try isNil("composed kind", c.compose(.IdentifierHead))
    }

    private func putExpectedWord() throws {
        c.put(.IdentifierHead, "i")
        try isTrue("put result", c.put(.IdentifierHead, "f"))
        try isNotNil("composed kind", c.compose(.IdentifierHead))
    }
}
