import PureSwiftUnit
@testable import Parser

class StringCharacterPeeper : CharacterPeeper {
    let s: String
    var i: String.Index

    init(_ s: String) {
        self.s = s
        self.i = s.startIndex
    }

    func look() -> Character? {
        if i == s.endIndex {
            return nil
        }
        return s[i]
    }

    func lookAhead() -> Character? {
        if i == s.endIndex || i.successor() == s.endIndex {
            return nil
        }
        return s[i.successor()]
    }

    func consume() {
        if i != s.endIndex {
            i = i.successor()
        }
    }
}

class TokenComposerTest : TestUnit {
    private var tc: TokenComposer!
    private var provider: () -> TokenComposer

    init(_ description: String, _ composerProvider: () -> TokenComposer) {
        provider = composerProvider
        super.init(description)
    }

    override func beforeCase() {
        tc = provider()
    }

    func putString(s: String) throws {
        let scp = StringCharacterPeeper(s)
        let classifier = CharacterClassifier(cp: scp)
        while let c = scp.look() {
            try isTrue("put character \"\(c)\"", tc.put(classifier.classify(), c))
            scp.consume()
        }
    }

    func putFail(c: Character) throws {
        let scp = StringCharacterPeeper(String(c))
        let classifier = CharacterClassifier(cp: scp)
        try isFalse("put character \"\(c)\"", tc.put(classifier.classify(), c))
    }

    func composeNil() throws {
        try isNil("composed result", tc.compose(.EndOfFile))
    }

    func putStringAndCompose(s: String) throws -> TokenKind {
        try putString(s)
        if let kind = tc.compose(.EndOfFile) {
            return kind
        } else {
            throw FailureReason.ExpectedNotNil("composed result")
        }
    }
}
