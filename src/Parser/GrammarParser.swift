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
    let ts: TokenStream

    init(_ ts: TokenStream) {
        self.ts = ts
    }

    func find(candidates: [TokenKind], startIndex: Int = 0) -> (Int, TokenKind) {
        var i = startIndex
        var kind = ts.look(i).kind
        while kind != .EndOfFile {
            for c in candidates {
                if kind == c {
                    return (i, kind)
                }
            }
            kind = ts.look(++i).kind
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

    func getValueRef(name: String) throws -> ValueRef {
        if name == "" {
            throw ParserError.Error("dummy error", ts.look().info)
        }
        return ValueRef(name)
    }

    func getImplicitParameterRef(num: Int) throws -> ValueRef {
        if num < 0 {
            throw ParserError.Error("dummy error", ts.look().info)
        }
        return ValueRef(String(num))
    }

    func getOperatorRef(name: String) throws -> OperatorRef {
        if name == "" {
            throw ParserError.Error("dummy error", ts.look().info)
        }
        return OperatorRef(name)
    }

    func getMemberRef(name: String) throws -> MemberRef {
        if name == "" {
            throw ParserError.Error("dummy error", ts.look().info)
        }
        return MemberRef(name)
    }

    func getMemberRef(num: Int) throws -> MemberRef {
        if num < 0 {
            throw ParserError.Error("dummy error", ts.look().info)
        }
        return MemberRef(String(num))
    }

    func getTypeRef(name: String) throws -> TypeRef {
        if name == "" {
            throw ParserError.Error("dummy error", ts.look().info)
        }
        return TypeRef(name)
    }
}
