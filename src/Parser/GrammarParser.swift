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

    func createTypeRef(name: String) throws -> TypeRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return TypeRef(name)
    }

    func createOperatorRef(name: String) throws -> OperatorRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return OperatorRef(name)
    }

    func createEnumCaseRef(name: String) throws -> EnumCaseRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return EnumCaseRef(name)
    }

    func createProtocolRef(name: String) throws -> ProtocolRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return ProtocolRef(name)
    }

    func createExtensionRef(name: String) throws -> ExtensionRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return ExtensionRef(name)
    }

    func getOperatorRef(name: String) throws -> OperatorRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return OperatorRef(name)
    }

    func getMemberRef(
        name: String, withClassName className: String? = nil
    ) throws -> MemberRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        if let c = className {
            return MemberRef("\(c).\(name)")
        }
        return MemberRef(name)
    }

    func getMemberRef(num: Int) throws -> MemberRef {
        if num < 0 {
            throw ts.fatal(.Dummy)
        }
        return MemberRef(String(num))
    }

    func getTypeRef(name: String) throws -> TypeRef {
        if name == "" {
            throw ts.fatal(.Dummy)
        }
        return TypeRef(name)
    }

    func isEnum(name: String) -> Bool {
        return true
    }
}
