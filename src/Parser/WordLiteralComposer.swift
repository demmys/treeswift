class WordLiteralComposer : TokenComposer {
    private var word: String
    private let kind: TokenKind
    private var index: String.Index
    private var succeeded = false

    init(_ word: String, _ kind: TokenKind) {
        self.word = word
        self.kind = kind
        index = word.startIndex
    }

    func put(_: CharacterClass, _ c: Character) -> Bool {
        if index == word.endIndex {
            succeeded = false
            return false
        }
        if word[index] == c {
            index = index.successor()
            if index == word.endIndex {
                succeeded = true
            }
            return true
        } else {
            index = word.endIndex
            return false
        }
    }

    func compose(_: CharacterClass) -> TokenKind? {
        if succeeded {
            return kind
        }
        return nil
    }
}
