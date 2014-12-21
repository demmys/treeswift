protocol TokenComposer {
    func put(CharacterClass, Character) -> Bool
    func compose(CharacterClass) -> TokenKind?
}

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

    func put(cc: CharacterClass, _ c: Character) -> Bool {
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

    func compose(CharacterClass) -> TokenKind? {
        if succeeded {
            return kind
        }
        return nil
    }
}

class IdentifierComposer : TokenComposer {
    private enum State {
        case Head
        case QuotedIdentifierHead
        case IdentifierCharacter, QuotedIdentifierCharacter
        case QuotedIdentifierTail
    }

    private var state = State.Head
    private var value: String?

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch state {
        case .Head:
            switch cc {
            case .IdentifierHead:
                value = String(c)
                state = .IdentifierCharacter
                return true
            case .BackQuote:
                state = .QuotedIdentifierHead
                return true
            default:
                value = nil
                return false
            }
        case .QuotedIdentifierHead:
            switch cc {
            case .IdentifierHead:
                value = String(c)
                state = .QuotedIdentifierCharacter
                return true
            default:
                value = nil
                return false
            }
        case .IdentifierCharacter:
            switch cc {
            case .IdentifierHead, .IdentifierFollow:
                value!.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .QuotedIdentifierCharacter:
            switch cc {
            case .IdentifierHead, .IdentifierFollow:
                value!.append(c)
                return true
            case .BackQuote:
                state = .QuotedIdentifierTail
                return true
            default:
                value = nil
                return false
            }
        case .QuotedIdentifierTail:
            value = nil
            return false
        }
    }

    func compose(follow: CharacterClass) -> TokenKind? {
        if let v = value {
            switch state {
            case .IdentifierCharacter:
                return .Identifier(v, false)
            case .QuotedIdentifierTail:
                return .Identifier(v, true)
            default:
                break
            }
        }
        return nil
    }
}

class IntegerLiteralComposer : TokenComposer {
    private enum State: Int {
        case Head
        case BaseSpecifier
        case BinaryDigit = 2
        case OctalDigit = 8
        case DecimalDigit = 10
        case HexadecimalDigit = 16
    }

    private let capitalA: UInt32 = 65
    private let capitalF: UInt32 = 70
    private let smallA: UInt32 = 97
    private let smallF: UInt32  = 102

    private var state = State.Head
    private var value: Int?

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch cc {
        case .IdentifierHead, .IdentifierFollow:
            switch state {
            case .Head:
                switch c {
                case "0":
                    state = .BaseSpecifier
                case "1"..."9":
                    value = String(c).toInt()
                    state = .DecimalDigit
                default:
                    value = nil
                    return false
                }
            case .BaseSpecifier:
                switch c {
                case "b":
                    state = .BinaryDigit
                case "o":
                    state = .OctalDigit
                case "x":
                    state = .HexadecimalDigit
                default:
                    state = .DecimalDigit
                    value = 0
                    return accumulate(c)
                }
            default:
                if value == nil {
                    value = 0
                }
                return accumulate(c)
            }
            return true
        default:
            value = nil
            return false
        }
    }

    func compose(follow: CharacterClass) -> TokenKind? {
        if let v = value {
            return .IntegerLiteral(v)
        }
        return nil
    }

    private func accumulate(c: Character) -> Bool {
        if c == "_" {
            return true
        }
        if let v = value {
            let base = state.rawValue
            value = v * base
            let s = String(c)
            if let x = s.toInt() {
                if x < base {
                    value = value! + x
                    return true
                }
                value = nil
                return false
            } else if base > 10 {
                let xs = s.unicodeScalars
                let x = xs[xs.startIndex].value
                if (capitalA <= x) && (x <= capitalF) {
                    value = value! + x - capitalA + 10
                    return true
                }
                if (smallA <= x) && (x <= smallF) {
                    value = value! + x - smallA + 10
                    return true
                }
                value = nil
                return false
            }
        }
        return false
    }
}

class OperatorComposer : TokenComposer {
    private enum State {
        case Head
        case ReservedOperator
        case DotOperatorHead
        case OperatorCharacter, DotOperatorCharacter
    }

    private var state = State.Head
    private var headSeparated: Bool = false
    private var value: String?

    init(prev: CharacterClass){
        headSeparated = isSeparator(prev, isPrev: true)
    }

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch state {
        case .Head:
            switch cc {
            case .OperatorHead:
                value = String(c)
                state = .OperatorCharacter
                return true
            case .DotOperatorHead:
                value = String(c)
                state = .DotOperatorHead
                return true
            case .Ampersand, .Question, .Exclamation:
                value = String(c)
                state = .ReservedOperator
                return true
            default:
                value = nil
                return false
            }
        case .DotOperatorHead:
            switch cc {
            case .DotOperatorHead, .Dot:
                value!.append(c)
                state = .DotOperatorCharacter
                return true
            default:
                value = nil
                return false
            }
        case .OperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow:
                value!.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .DotOperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow, .DotOperatorHead, .Dot:
                value!.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .ReservedOperator:
            value = nil
            return false
        }
    }

    // TODO single "&" cannot become a custom prefix operator
    func compose(follow: CharacterClass) -> TokenKind? {
        if let v = value {
            switch state {
            case .OperatorCharacter, .DotOperatorCharacter:
                if isSeparator(follow, isPrev: false) {
                    if headSeparated {
                        return .BinaryOperator(v)
                    }
                    return .PostfixOperator(v)
                } else {
                    if headSeparated {
                        return .PrefixOperator(v)
                    }
                    return .BinaryOperator(v)
                }
            default:
                break
            }
        }
        return nil
    }

    private func isSeparator(cc: CharacterClass, isPrev: Bool) -> Bool {
        switch cc {
        case .EndOfFile, .LineFeed, .Semicolon, .Space:
            return true
        case .LeftParenthesis, .LeftBrace, .LeftBracket:
            return isPrev
        case .RightParenthesis, .RightBrace, .RightBracket:
            return !isPrev
        default:
            return false
        }
    }
}
