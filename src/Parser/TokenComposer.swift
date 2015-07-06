protocol TokenComposer {
    func put(CharacterClass, Character) -> Bool
    func compose(CharacterClass) -> TokenKind?
}

private let capitalA: Int = 65
private let capitalF: Int = 70
private let smallA: Int = 97
private let smallF: Int  = 102

func hex(c: Character) -> Int? {
    let s = String(c)
    guard let v = Int(s) else {
        let xs = s.unicodeScalars
        let x = Int(xs[xs.startIndex].value)
        if (capitalA <= x) && (x <= capitalF) {
            return x - capitalA + 10
        }
        if (smallA <= x) && (x <= smallF) {
            return x - smallA + 10
        }
        return nil
    }
    return v
}
