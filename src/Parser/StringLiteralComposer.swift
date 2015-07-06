class StringLiteralComposer : TokenComposer {
    init() {}

    func put(CharacterClass, Character) -> Bool {
        return false
    }

    func compose(CharacterClass) -> TokenKind? {
        return nil
    }
}
