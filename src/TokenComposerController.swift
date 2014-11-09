private protocol TokenComposer {
    func put(c: Character) -> Bool
    func compose() -> TokenKind?
}

private class IntegerLiteral : TokenComposer {
    private enum State: Int {
        case Initial
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

    private var state = State.Initial
    private var value: Int!

    init() {}

    func put(c: Character) -> Bool {
        switch state {
        case .Initial:
            switch c {
            case "0":
                state = .BaseSpecifier
            case "1"..."9":
                value = String(c).toInt()
                state = .DecimalDigit
            default:
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
    }

    func compose() -> TokenKind? {
        switch state {
        case .Initial, .BaseSpecifier:
            return nil
        default:
            return .IntegerLiteral(value)
        }
    }

    private func accumulate(c: Character) -> Bool {
        if c == "_" {
            return true
        }
        let base = state.rawValue
        value = value * base
        let s = String(c)
        if let x = s.toInt() {
             value = value + x
             return true
        } else if base > 10 {
            let xs = s.unicodeScalars
            let x = xs[xs.startIndex].value
            if (capitalA <= x) && (x <= capitalF) {
                value = value + x - capitalA + 10
                return true
            }
            if (smallA <= x) && (x <= smallF) {
                value = value + x - smallA + 10
            }
            return true
        }
        return false
    }
}

class TokenComposersController {
    private var composers: [TokenComposer]
    private var fileName: String

    init(_ fileName: String) {
        self.fileName = fileName
        composers = [
            IntegerLiteral()
        ]
    }

    func put(c: Character) {
        composers = composers.filter({
            $0.put(c)
        })
    }

    func fixKind() -> TokenKind {
        var tokenKinds = composers.map({
            $0.compose()
        }).filter({
            $0 != nil
        })
        switch tokenKinds.count {
        case 0:
            return .Error(ErrorInfo(target: fileName,
                                    reason: "Invalid token string"))
        case 1:
            return tokenKinds[0]!
        default:
            return .Error(ErrorInfo(target: fileName,
                                    reason: "Ambiguous token string"))
        }
    }
}
