private protocol TokenComposer {
    func put(CharacterClass, Character) -> Bool
    func compose(CharacterClass) -> TokenKind?
}

private class Operator : TokenComposer {
    private enum State {
        case Head
        case DotOperatorHead
        case OperatorCharacter, DotOperatorCharacter
    }

    private var state: State = .Head
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
            default:
                value = nil
                return false
            }
        case .DotOperatorHead:
            switch cc {
            case .Dot:
                value?.append(c)
                state = .DotOperatorCharacter
                return true
            default:
                value = nil
                return false
            }
        case .OperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow:
                value?.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .DotOperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow, .DotOperatorHead, .Dot:
                value?.append(c)
                return true
            default:
                value = nil
                return false
            }
        }
    }

    func compose(follow: CharacterClass) -> TokenKind? {
        if let v = value {
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
        }
        return nil
    }

    private func isSeparator(cc: CharacterClass, isPrev: Bool) -> Bool {
        switch cc {
        case .EndOfFile, .LineFeed, .Semicolon, .Space:
            return true
        case .LeftParenthesis:
            return isPrev
        case .RightParenthesis:
            return !isPrev
        default:
            return false
        }
    }
}

private class IntegerLiteral : TokenComposer {
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

    private var state: State = .Head
    private var value: Int?

    init() {}

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch cc {
        case .Literal:
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

class TokenComposersController {
    private var composers: [TokenComposer]

    init(prev: CharacterClass) {
        composers = [
            IntegerLiteral(),
            Operator(prev: prev)
        ]
    }

    func put(cc: CharacterClass, c: Character) {
        composers = composers.filter({
            $0.put(cc, c)
        })
    }

    func fixKind(follow: CharacterClass) -> TokenKind {
        var tokenKinds = composers.map({
            $0.compose(follow)
        }).filter({
            $0 != nil
        })
        switch tokenKinds.count {
        case 0:
            return .Error(.InvalidToken)
        case 1:
            return tokenKinds[0]!
        default:
            return .Error(.AmbiguousToken)
        }
    }
}
