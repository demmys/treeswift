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
    private enum AccumlatePosition {
        case Integral
        case Fraction
        case Exponent
    }
    private enum State {
        case Head
        case BaseSpecifier
        case HeadDigit(Int, AccumlatePosition)
        case FollowingDigit(Int, AccumlatePosition)
        case ExponentHead(Int)
        case Failed
    }

    private let capitalA: Int64 = 65
    private let capitalF: Int64 = 70
    private let smallA: Int64 = 97
    private let smallF: Int64  = 102

    private var state = State.Head
    private var integralPart: Int64 = 0
    private var fractionPart: Int64?
    private var exponentPart: Int64?

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch cc {
        case .Digit, .IdentifierHead, .Dot, .OperatorHead:
            switch state {
            case .Head:
                switch c {
                case "0":
                    state = .BaseSpecifier
                case "1"..."9":
                    integralPart = Int64(String(c))!
                    state = .FollowingDigit(10, .Integral)
                default:
                    state = .Failed
                    return false
                }
            case .BaseSpecifier:
                switch c {
                case "b":
                    state = .HeadDigit(2, .Integral)
                case "o":
                    state = .HeadDigit(8, .Integral)
                case "x":
                    state = .HeadDigit(16, .Integral)
                case "1"..."9":
                    integralPart = Int64(String(c))!
                    state = .FollowingDigit(10, .Integral)
                case "_", "0":
                    state = .FollowingDigit(10, .Integral)
                case ".":
                    state = .HeadDigit(10, .Fraction)
                case "e", "E":
                    state = .ExponentHead(10)
                default:
                    state = .Failed
                    return false
                }
            case let .HeadDigit(base, pos):
                switch c {
                case "0"..."9", "a"..."f", "A"..."F":
                    if accumulate(base, pos, c) {
                        state = .FollowingDigit(base, pos)
                    } else {
                        state = .Failed
                        return false
                    }
                default:
                    state = .Failed
                    return false
                }
            case let .FollowingDigit(base, pos):
                switch c {
                case "0"..."9", "a"..."d", "f", "A"..."D", "F":
                    guard accumulate(base, pos, c) else {
                        state = .Failed
                        return false
                    }
                case "_":
                    break
                case ".":
                    guard base >= 10 && pos == .Integral else {
                        state = .Failed
                        return false
                    }
                    state = .HeadDigit(base, .Fraction)
                case "e", "E":
                    if base == 10 && pos != .Exponent {
                        state = .ExponentHead(base)
                    } else if base == 16 {
                        add(16, pos, 14)
                    } else {
                        state = .Failed
                        return false
                    }
                case "p", "P":
                    guard base == 16 && pos != .Exponent else {
                        state = .Failed
                        return false
                    }
                    state = .ExponentHead(base)
                default:
                    state = .Failed
                    return false
                }
            case let .ExponentHead(base):
                switch c {
                case "0"..."9", "a"..."f", "A"..."F":
                    if accumulate(base, .Exponent, c) {
                        state = .FollowingDigit(base, .Exponent)
                    } else {
                        state = .Failed
                        return false
                    }
                case "+":
                    exponentPart = 1
                    state = .HeadDigit(base, .Exponent)
                case "-":
                    exponentPart = -1
                    state = .HeadDigit(base, .Exponent)
                default:
                    state = .Failed
                    return false
                }
            case .Failed:
                return false
            }
            return true
        default:
            state = .Failed
            return false
        }
    }

    private func accumulate(
        base: Int, _ pos: AccumlatePosition, _ c: Character
    ) -> Bool {
        if base == 16 {
            if let v = hex(c) {
                add(16, pos, v)
                return true
            }
        } else if let v = Int64(String(c)) {
            add(base, pos, v)
            return true
        }
        return false
    }

    private func hex(c: Character) -> Int64? {
        let s = String(c)
        guard let v = Int64(s) else {
            let xs = s.unicodeScalars
            let x = Int64(xs[xs.startIndex].value)
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

    private func add(base: Int, _ pos: AccumlatePosition, _ v: Int64) {
        switch pos {
        case .Integral:
            integralPart = integralPart * Int64(base) + v
        case .Fraction:
            if let f = fractionPart {
                fractionPart = f * Int64(base) + v 
            } else {
                fractionPart = v
            }
        case .Exponent:
            if let e = exponentPart {
                exponentPart = e * Int64(base) + v
            } else {
                exponentPart = v
            }
        }
    }

    func compose(CharacterClass) -> TokenKind? {
        switch state {
        case .BaseSpecifier:
            return TokenKind.IntegerLiteral(integralPart, decimalDigits: true)
        case let .FollowingDigit(base, pos):
            if pos == .Integral {
                return TokenKind.IntegerLiteral(
                    integralPart, decimalDigits: base == 10
                )
            }
            var value: Double = Double(integralPart)
            let b = Double(base)
            if let fp = fractionPart {
                var f = Double(fp)
                while f > 1 {
                    f /= b
                }
                value += f
            }
            if let e = exponentPart {
                if e > 0 {
                    for _ in 0..<e {
                        value *= b
                    }
                } else {
                    for _ in e..<0 {
                        value /= b
                    }
                }
            }
            return TokenKind.FloatingPointLiteral(value)
        default:
            return nil
        }
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
