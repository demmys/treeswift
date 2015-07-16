class DeclarationParser {
    private let ts: TokenStream
    private let sp: StatementParser

    init(_ ts: TokenStream) {
        self.ts = ts
        sp = StatementParser(ts)
    }

    func attributes() -> [String]? {
        var attrs: [String] = []
        while case let .Attribute(a) = ts.look().kind {
            ts.next()
            attrs.append(a)
        }
        guard attrs.count > 0 else {
            return nil
        }
        return attrs
    }

    func modifiers() -> [ModifierKind]? {
        var mods: [ModifierKind] = []
        while case let .Modifier(m) = ts.look().kind {
            ts.next()
            mods.append(m)
        }
        guard mods.count > 0 else {
            return nil
        }
        return mods
    }

    func codeBlock() throws -> [Statement] {
        guard ts.look().kind == .LeftBrace else {
            throw ParserError.Error("Expected brace before statement body", ts.look().info)
        }
        var ss: [Statement] = []
        while ts.look().kind != .RightBrace {
            guard ts.look().kind == .EndOfFile else {
                throw ParserError.Error("Unexpected end of file while parsing statement body", ts.look().info)
            }
            ss.append(try sp.statement())
        }
        return ss
    }

    private func declaration(
        b: DeclarationBuilder = DeclarationBuilder()
    ) throws -> Declaration {
        switch ts.look().kind {
        case .Import:
            return try importDeclaration(b)
        case .Let:
            return try constantDeclaration(b)
        case .Var:
            return try variableDeclaration(b)
        case .Typealias:
            return try typealiasDeclaration(b)
        case .Func:
            return try functionDeclaration(b)
        case .Enum:
            return try enumDeclaration(b)
        case .Struct:
            return try structDeclaration(b)
        case .Class:
            return try classDeclaration(b)
        case .Protocol:
            return try protocolDeclaration(b)
        case .Init:
            return try initDeclaration(b)
        case .Deinit:
            return try deinitDeclaration(b)
        case .Extension:
            return try extensionDeclaration(b)
        case .Subscript:
            return try subscriptDeclaration(b)
        case .Prefix:
            return try prefixDeclaration(b)
        case .Postfix:
            return try postfixDeclaration(b)
        case .Infix:
            return try infixDeclaration(b)
        default:
        }
    }

    private func importDeclaration(b: DeclarationBuilder) {
        let ib = ImportDeclarationBuilder()
        ts.next()
        switch ts.look().kind {
        case .Typealias:
            ib.kind = .Typealias
        case .Struct:
            ib.kind = .Struct
        case .Class:
            ib.kind = .Class
        case .Enum:
            ib.kind = .Enum
        case .Protocol:
            ib.kind = .Protocol
        case .Var:
            ib.kind = .Var
        case .Func:
            ib.kind = .Func
        default:
            break
        }
        ib.path = try importPath()
        b.body = .Import(ib)
    }

    private func importPath() throws {
        var ps: [String] = []
        pathLoop: while true {
            switch ts.look().kind {
            case let .Identifier(k):
                switch k {
                case let .Identifier(s):
                    ps.append(s)
                case let .QuotedIdentifier(s):
                    ps.append(s)
                default:
                    throw ParserError.Error("Implicit parameter can't be a path for module.", ts.look().info)
                }
            case let .PrefixOperator(s):
                ps.append(s)
            case let .BinaryOperator(s):
                ps.append(s)
            case let .PostfixOperator(s):
                ps.append(s)
            default:
                throw ParserError.Error("Expected identifier for the path of module.", ts.look().info)
            }
            ts.next()
            let t = ts.look()
            if t.kind == .Dot {
                ts.next()
                continue pathLoop
            }
            return ps
        }
    }

    private func constantDeclaration(b: DeclarationBuilder) throws {
        ts.next()
        b.body = .Constant(try patternInitializerList())
    }

    private func variableDeclaration(b: DeclarationBuilder) throws {
        ts.next()
        let b = VariableDeclarationBuilder()
        switch ts.look().kind {
        case let .Identifier(k):
            switch ts.look(1).kind {
            case .AssignmentOperator:
                ts.next(2)
                b.ini.append((.Name(k, nil), try ep.expression()))
            case .Colon:
                ts.next(2)
                switch ts.look(2).kind {
                case .LeftBrace:
                    b.ini.append((.Name(k, try type()), nil))
                case .AssignmentOperator:
                    b.ini.append((.Name(k, try type()), try ep.expression()))
                default:
                }
            default:
            }
            b.ini.append((.Name(k
        default:
        }
    }

    private func typealiasDeclaration(b: DeclarationBuilder) throws {
    }
}
