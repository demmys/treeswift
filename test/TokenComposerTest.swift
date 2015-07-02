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

    func putStringAndCompose(s: String) throws -> TokenKind {
        let scp = StringCharacterPeeper(s)
        let classifier = CharacterClassifier(cp: scp)
        while let c = scp.look() {
            try isTrue("put character \"\(c)\"", tc.put(classifier.classify(), c))
            scp.consume()
        }
        if let kind = tc.compose(.EndOfFile) {
            return kind
        } else {
            throw FailureReason.ExpectedNotNil("composed result")
        }
    }
}
