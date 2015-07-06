class StringLiteralComposer : TokenComposer {
    private enum State {
        case Head
        case Normal
        case Escaped
        case UnicodeHead
        case UnicodeScalar
        case Completed
        case Failed
    }

    private var value = ""
    private var unicodeScalar = 0
    private var state = State.Head

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch state {
        case .Head:
            if case .DoubleQuote = cc {
                state = .Normal
                return true
            }
        case .Normal:
            switch cc {
            case .BackSlash:
                state = .Escaped
                return true
            case .LineFeed, .CarriageReturn:
                break
            case .DoubleQuote:
                state = .Completed
                return true
            default:
                value.append(c)
                return true
            }
        case .Escaped:
            state = .Normal
            switch c {
            case "0":
                value.append("\0" as Character)
            case "\\":
                value.append("\\" as Character)
            case "t":
                value.append("\t" as Character)
            case "n":
                value.append("\n" as Character)
            case "r":
                value.append("\r" as Character)
            case "\"":
                value.append("\"" as Character)
            case "'":
                value.append("\'" as Character)
            case "u":
                state = .UnicodeHead
            case "(":
                state = .Failed
                return false
            default:
                value.append(c)
            }
            return true
        case .UnicodeHead:
            if case .LeftBrace = cc {
                state = .UnicodeScalar
                unicodeScalar = 0
                return true
            }
        case .UnicodeScalar:
            switch c {
            case "0"..."9", "a"..."f", "A"..."F":
                unicodeScalar = unicodeScalar * 16 + hex(c)!
                return true
            case "}":
                // TODO check whether the correct unicode scalar or not
                value.append(UnicodeScalar(unicodeScalar))
                state = .Normal
                return true
            default:
                break
            }
        default:
            break
        }
        state = .Failed
        return false
    }

    func compose(CharacterClass) -> TokenKind? {
        guard case .Completed = state else {
            return nil
        }
        return .StringLiteral(value)
    }
}
