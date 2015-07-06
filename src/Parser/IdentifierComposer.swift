class IdentifierComposer : TokenComposer {
    private enum State {
        case Head
        case QuotedIdentifierHead
        case IdentifierCharacter, QuotedIdentifierCharacter
        case ImplicitParameterDigit
        case QuotedIdentifierTail
    }

    private var state = State.Head
    private var stringValue: String?
    private var intValue: Int?

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch state {
        case .Head:
            switch cc {
            case .IdentifierHead:
                stringValue = String(c)
                state = .IdentifierCharacter
                return true
            case .BackQuote:
                state = .QuotedIdentifierHead
                return true
            case .Dollar:
                intValue = 0
                state = .ImplicitParameterDigit
                return true
            default:
                stringValue = nil
                return false
            }
        case .QuotedIdentifierHead:
            switch cc {
            case .IdentifierHead:
                stringValue = String(c)
                state = .QuotedIdentifierCharacter
                return true
            default:
                stringValue = nil
                return false
            }
        case .IdentifierCharacter:
            switch cc {
            case .IdentifierHead, .IdentifierFollow, .Digit, .Underscore:
                stringValue!.append(c)
                return true
            default:
                stringValue = nil
                return false
            }
        case .QuotedIdentifierCharacter:
            switch cc {
            case .IdentifierHead, .IdentifierFollow, .Digit, .Underscore:
                stringValue!.append(c)
                return true
            case .BackQuote:
                state = .QuotedIdentifierTail
                return true
            default:
                stringValue = nil
                return false
            }
        case .ImplicitParameterDigit:
            switch cc {
            case .Digit:
                intValue = intValue! * 10 + Int(String(c))!
                return true
            default:
                stringValue = nil
                return false
            }
        case .QuotedIdentifierTail:
            stringValue = nil
            return false
        }
    }

    func compose(CharacterClass) -> TokenKind? {
        switch state {
        case .IdentifierCharacter:
            if let v = stringValue {
                return .Identifier(.Identifier(v))
            }
        case .QuotedIdentifierTail:
            if let v = stringValue {
                return .Identifier(.QuotedIdentifier(v))
            }
        case .ImplicitParameterDigit:
            if let v = intValue {
                return .Identifier(.ImplicitParameter(v))
            }
        default:
            break
        }
        return nil
    }
}
