protocol TokenComposer {
    func put(CharacterClass, Character) -> Bool
    func compose(CharacterClass) -> TokenKind?
}
