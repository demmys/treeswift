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

    func put(CharacterClass, _ c: Character) -> Bool {
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

class NumericLiteralComposer : TokenComposer {
    private enum State: Int {
        case Head
        case BaseSpecifier
        case BinaryDigit = 2
        case OctalDigit = 8
        case DecimalDigit = 10
        case HexadecimalDigit = 16
    }

    private let capitalA: Int64 = 65
    private let capitalF: Int64 = 70
    private let smallA: Int64 = 97
    private let smallF: Int64  = 102

    private var state = State.Head
    private var value: Int64?

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch cc {
        case .Digit, .IdentifierHead:
            switch state {
            case .Head:
                switch c {
                case "0":
                    value = 0
                    state = .BaseSpecifier
                case "1"..."9":
                    value = Int64(String(c))
                    state = .DecimalDigit
                default:
                    value = nil
                    return false
                }
            case .BaseSpecifier:
                switch c {
                case "b":
                    value = nil
                    state = .BinaryDigit
                case "o":
                    value = nil
                    state = .OctalDigit
                case "x":
                    value = nil
                    state = .HexadecimalDigit
                default:
                    state = .DecimalDigit
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

    func compose(CharacterClass) -> TokenKind? {
        if let v = value {
            switch state {
            case .DecimalDigit:
                return .IntegerLiteral(v, decimalDigits: true)
            default:
                return .IntegerLiteral(v, decimalDigits: false)
            }
        }
        return nil
    }

    private func accumulate(c: Character) -> Bool {
        if c == "_" {
            return true
        }
        if let v = value {
            let base = Int64(state.rawValue)
            value = v * base
            let s = String(c)
            if let x = Int64(s) {
                if x < base {
                    value = value! + x
                    return true
                }
                value = nil
                return false
            } else if base > 10 {
                let xs = s.unicodeScalars
                let x = Int64(xs[xs.startIndex].value)
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

class StringLiteralComposer : TokenComposer {
    init() {}

    func put(CharacterClass, Character) -> Bool {
        return false
    }

    func compose(CharacterClass) -> TokenKind? {
        return nil
    }
}

class OperatorComposer : TokenComposer {
    private enum State {
        case Head
        case ReservedOperator(CharacterClass)
        case DotOperatorHead
        case OperatorCharacter, DotOperatorCharacter
    }

    private var state = State.Head
    private var prev: CharacterClass
    private var value: String?

    init(prev: CharacterClass){
        self.prev = prev
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
            case .LessThan, .GraterThan, .Ampersand, .Question, .Exclamation:
                value = String(c)
                state = .ReservedOperator(cc)
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
            case .OperatorHead, .OperatorFollow, .LessThan, .GraterThan,
                 .Ampersand, .Question, .Exclamation, .Equal, .Arrow,
                 .LineCommentHead, .BlockCommentHead, .BlockCommentTail:
                value!.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .DotOperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow, .LessThan, .GraterThan,
                 .Ampersand, .Question, .Exclamation, .Equal, .Arrow,
                 .LineCommentHead, .BlockCommentHead, .BlockCommentTail,
                 .DotOperatorHead, .Dot:
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

    func compose(follow: CharacterClass) -> TokenKind? {
        if let v = value {
            let kind = createKind(prev: self.prev, value: v, follow: follow)
            switch state {
            case .OperatorCharacter, .DotOperatorCharacter:
                return kind
            case let .ReservedOperator(cc):
                switch cc {
                case .LessThan:
                    switch kind {
                    case .PrefixOperator:
                        return .PrefixLessThan
                    default:
                        return kind
                    }
                case .GraterThan:
                    switch kind {
                    case .PostfixOperator:
                        return .PostfixGraterThan
                    default:
                        return kind
                    }
                case .Ampersand:
                    switch kind {
                    case .PrefixOperator:
                        return .PrefixAmpersand
                    default:
                        return kind
                    }
                case .Question:
                    switch kind {
                    case .PrefixOperator:
                        return .PrefixQuestion
                    case .BinaryOperator:
                        return .BinaryQuestion
                    case .PostfixOperator:
                        return .PostfixQuestion
                    default:
                        assert(false,
                               "[System Error] Unimplemented operator type found.")
                    }
                case .Exclamation:
                    switch kind {
                    case .PostfixOperator:
                        return .PostfixExclamation
                    default:
                        return kind
                    }
                default:
                    assert(false,
                           "[System Error] Unimplemented reserved operator found.")
                }
            default:
                break
            }
        }
        return nil
    }

    private func createKind(prev prev: CharacterClass, value: String,
                            follow: CharacterClass) -> TokenKind {
        let headSeparated = isSeparator(prev, isPrev: true)
        let tailSeparated = isSeparator(follow, isPrev: false)
        if headSeparated {
            if tailSeparated {
                return .BinaryOperator(value)
            }
            return .PrefixOperator(value)
        } else {
            if tailSeparated {
                return .PostfixOperator(value)
            }
            return .BinaryOperator(value)
        }
    }

    private func isSeparator(cc: CharacterClass, isPrev: Bool) -> Bool {
        switch cc {
        case .EndOfFile, .LineFeed, .Semicolon, .Space:
            return true
        case .BlockCommentTail, .LeftParenthesis, .LeftBrace, .LeftBracket:
            return isPrev
        case .BlockCommentHead, .RightParenthesis, .RightBrace, .RightBracket:
            return !isPrev
        default:
            return false
        }
    }
}
