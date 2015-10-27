import AST

class GrammarParser {
    let integerLiteral = TokenKind.IntegerLiteral(0, decimalDigits: true)
    let floatingPointLiteral = TokenKind.FloatingPointLiteral(0)
    let booleanLiteral = TokenKind.BooleanLiteral(true)
    let stringLiteral = TokenKind.StringLiteral("")
    let identifier = TokenKind.Identifier("")
    let implicitParameterName = TokenKind.ImplicitParameterName(0)
    let prefixOperator = TokenKind.PrefixOperator("")
    let binaryOperator = TokenKind.BinaryOperator("")
    let postfixOperator = TokenKind.PostfixOperator("")
    let modifier = TokenKind.Modifier(.Convenience)
    let ts: TokenStream

    init(_ ts: TokenStream) {
        self.ts = ts
    }

    func find(candidates: [TokenKind], startIndex: Int = 0) -> (Int, TokenKind) {
        var i = startIndex
        var kind = ts.look(i, skipLineFeed: false).kind
        while kind != .EndOfFile {
            for c in candidates {
                if kind == c {
                    return (i, kind)
                }
            }
            kind = ts.look(++i, skipLineFeed: false).kind
        }
        return (i, .EndOfFile)
    }

    func findInsideOfBrackets(
        candidates: [TokenKind], startIndex: Int = 0
    ) -> (Int, TokenKind) {
        var i = startIndex
        var nest = 0
        while true {
            let kind = ts.look(i).kind
            switch kind {
            case .EndOfFile:
                return (i, .EndOfFile)
            case .LeftBracket:
                ++nest
            case .RightBracket:
                if nest == 0 {
                    return (i, .RightBracket)
                }
                --nest
            default:
                for c in candidates {
                    if kind == c {
                        return (i, kind)
                    }
                }
                ++i
            }
        }
    }

    func findParenthesisClose(startIndex: Int = 0) -> Int? {
        var i = startIndex
        var nest = 0
        while true {
            let kind = ts.look(i).kind
            switch kind {
            case .EndOfFile:
                return nil
            case .LeftParenthesis:
                ++nest
            case .RightParenthesis:
                if nest == 0 {
                    return i
                }
                --nest
            default:
                ++i
            }
        }
    }

    func findRightParenthesisBefore(
        candidates: [TokenKind], startIndex: Int = 0
    ) -> Int? {
        var i = startIndex
        var nest = 0
        while true {
            let kind = ts.look(i).kind
            switch kind {
            case .EndOfFile:
                return nil
            case .LeftParenthesis:
                ++nest
            case .RightParenthesis:
                if nest == 0 {
                    return i
                }
                --nest
            default:
                for c in candidates {
                    if kind == c {
                        return nil
                    }
                }
                ++i
            }
        }
    }

    func isEnum(name: String) -> Bool {
        return true
    }
}
