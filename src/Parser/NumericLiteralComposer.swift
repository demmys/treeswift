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

    private var state = State.Head
    private var integralPart: Int64 = 0
    private var fractionPart: Int64?
    private var exponentPart: Int64?
    private var negativeExponent = false

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
                case "a"..."d", "f", "A"..."D", "F":
                    if case .Exponent = pos {
                        state = .Failed
                        return false
                    }
                    fallthrough
                case "0"..."9":
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
                case "0"..."9":
                    if accumulate(base, .Exponent, c) {
                        state = .FollowingDigit(base, .Exponent)
                    } else {
                        state = .Failed
                        return false
                    }
                case "+":
                    state = .HeadDigit(base, .Exponent)
                case "-":
                    negativeExponent = true
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
                add(16, pos, Int64(v))
                return true
            }
        } else if let v = Int64(String(c)) {
            add(base, pos, v)
            return true
        }
        return false
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
                exponentPart = e * 10 + v
            } else {
                exponentPart = v
            }
        }
    }

    func compose(_: CharacterClass) -> TokenKind? {
        switch state {
        case .BaseSpecifier:
            return TokenKind.IntegerLiteral(integralPart, decimalDigits: true)
        case let .FollowingDigit(base, pos):
            if base == 16 && fractionPart != nil && exponentPart == nil {
                return nil
            }
            if pos == .Integral {
                return TokenKind.IntegerLiteral(
                    integralPart, decimalDigits: base == 10
                )
            }
            var value: Double = Double(integralPart)
            let b: Double = base == 10 ? 10 : 2
            if let fp = fractionPart {
                var f = Double(fp)
                while f > 1 {
                    f /= b
                }
                value += f
            }
            if let e = exponentPart {
                if negativeExponent {
                    for _ in 0..<e {
                        value /= b
                    }
                } else {
                    for _ in 0..<e {
                        value *= b
                    }
                }
            }
            return TokenKind.FloatingPointLiteral(value)
        default:
            return nil
        }
    }
}
