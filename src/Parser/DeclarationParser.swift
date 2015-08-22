class DeclarationParser : GrammarParser {
    private var prp: ProcedureParser!
    private var ptp: PatternParser!
    private var ep: ExpressionParser!
    private var tp: TypeParser!
    private var ap: AttributesParser!

    func setParser(
        procedureParser prp: ProcedureParser!,
        patternParser ptp: PatternParser,
        expressionParser ep: ExpressionParser,
        typeParser tp: TypeParser,
        attributesParser ap: AttributesParser
    ) {
        self.prp = prp
        self.ptp = ptp
        self.ep = ep
        self.tp = tp
        self.ap = ap
    }

    func declaration() throws -> Declaration {
        switch ts.match([.Var]) {
        case .Var:
            return try variableDeclaration()
        default:
            throw ParserError.Error("Declarations except for the variable declaration are not implemented yet", ts.look().info)
        }
    }

    func variableDeclaration(
        attrs: [Attribute] = [], _ mods: [Modifier] = []
    ) throws -> Declaration {
        switch ts.look().kind {
        case .Underscore, .LeftParenthesis:
            let x = PatternInitializerDeclaration(isVariable: true)
            x.inits = try patternInitializerList()
            return x
        case .Identifier:
            let inits = try patternInitializerList()
            if ts.test([.LeftBrace]) {
                guard inits.count == 1 else {
                    throw ParserError.Error("When the variable has blocks, you can define only one variable in a declaration.", ts.look().info)
                }
                return try variableBlockDeclaration(inits[0])
            }
            return PatternInitializerDeclaration(isVariable: true, inits: inits)
        default:
            throw ParserError.Error("Expected identifier or declarational pattern for variable declaration.", ts.look().info)
        }
    }

    func variableBlockDeclaration(ini: (Pattern, Expression?)) throws -> VariableBlockDeclaration {
        switch ini.0 {
        case let .IdentifierPattern(r):
            guard let e = ini.1 else {
                throw ParserError.Error("Expected type annotation or initializer for variable declaration with block.", ts.look().info)
            }
            let x = VariableBlockDeclaration(r)
            x.specifier = .Initializer(e)
            x.blocks = try willSetDidSetBlock()
            return x
        case let .TypedIdentifierPattern(r, t, attrs):
            let x = VariableBlockDeclaration(r)
            if let e = ini.1 {
                x.specifier = .TypedInitializer(t, attrs, e)
                x.blocks = try willSetDidSetBlock()
                return x
            }
            x.specifier = .TypeAnnotation(t, attrs)
            x.blocks = try getterSetterBlock()
            return x
        default:
            throw ParserError.Error("Only identifier pattern can appear in the variable declaration with blocks.", ts.look().info)
        }
    }

    private func getterSetterBlock(
        attrs: [Attribute] = [], ahead: Int = 0
    ) throws -> VariableBlocks {
        switch ts.match([.Get, .Set], ahead: ahead) {
        case .Get:
            let g = VariableBlock(attrs: attrs)
            g.body = try prp.proceduresBlock()
            if ts.test([.RightBrace]) {
                return .GetterSetter(getter: g, setter: nil)
            }
            let setAttrs = try ap.attributes()
            guard ts.test([.Set]) else {
                throw ParserError.Error("Expected setter clause after getter clause", ts.look().info)
            }
            let s = try setterBlock(setAttrs)
            guard ts.test([.RightBrace]) else {
                throw ParserError.Error("Expected '}' at the end of getter-setter clause", ts.look().info)
            }
            return .GetterSetter(getter: g, setter: s)
        case .Set:
            let s = try setterBlock(attrs)
            let getAttrs = try ap.attributes()
            guard ts.test([.Get]) else {
                throw ParserError.Error("Expected getter clause after setter clause.", ts.look().info)
            }
            let g = VariableBlock(attrs: getAttrs)
            g.body = try prp.proceduresBlock()
            guard ts.test([.RightBrace]) else {
                throw ParserError.Error("Expected '}' at the end of getter-setter clause", ts.look().info)
            }
            return .GetterSetter(getter: g, setter: s)
        case .Atmark:
            // Expect getter, setter or procedure beggining with attributes
            // To avoid consuming attributes for procedure, use TokenStream.look only
            let (firstAttrs, i) = try ap.lookAfterAttributes()
            switch ts.look(i).kind {
            case .Get, .Set:
                return try getterSetterBlock(firstAttrs, ahead: i)
            default:
                break
            }
            fallthrough
        default:
            let g = VariableBlock()
            g.body = try prp.procedures()
            guard ts.test([.RightBrace]) else {
                throw ParserError.Error("Expected '}' after procedures block", ts.look().info)
            }
            return .GetterSetter(getter: g, setter: nil)
        }
    }

    private func setterBlock(attrs: [Attribute] = []) throws -> VariableBlock {
        let x = VariableBlock()
        x.attrs = attrs
        if ts.test([.LeftParenthesis]) {
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ParserError.Error("Expected variable name for setter parameter", ts.look().info)
            }
            x.param = try createValueRef(s)
            guard ts.test([.RightParenthesis]) else {
                throw ParserError.Error("Expected ')' after setter parameter name", ts.look().info)
            }
        }
        x.body = try prp.proceduresBlock()
        return x
    }

    private func willSetDidSetBlock() throws -> VariableBlocks {
        let attrs = try ap.attributes()
        switch ts.match([.WillSet, .DidSet]) {
        case .WillSet:
            let ws = try setterBlock(attrs)
            if ts.test([.RightBrace]) {
                return .WillSetDidSet(willSetter: ws, didSetter: nil)
            }
            let didSetAttrs = try ap.attributes()
            guard ts.test([.DidSet]) else {
                throw ParserError.Error("Expected did-setter clause after getter clause", ts.look().info)
            }
            let ds = try setterBlock(didSetAttrs)
            guard ts.test([.RightBrace]) else {
                throw ParserError.Error("Expected '}' at the end of will-setter, did-setter clause", ts.look().info)
            }
            return .WillSetDidSet(willSetter: ws, didSetter: ds)
        case .DidSet:
            let ds = try setterBlock(attrs)
            if ts.test([.RightBrace]) {
                return .WillSetDidSet(willSetter: nil, didSetter: ds)
            }
            let willSetAttrs = try ap.attributes()
            guard ts.test([.WillSet]) else {
                throw ParserError.Error("Expected will-setter clause after getter clause", ts.look().info)
            }
            let ws = try setterBlock(willSetAttrs)
            guard ts.test([.RightBrace]) else {
                throw ParserError.Error("Expected '}' at the end of will-setter, did-setter clause", ts.look().info)
            }
            return .WillSetDidSet(willSetter: ws, didSetter: ds)
        default:
            throw ParserError.Error("Expected will-setter or did-setter.", ts.look().info)
        }
    }

    func functionResult() throws -> ([Attribute], Type)? {
        guard ts.test([.Arrow]) else {
            return nil
        }
        return (try ap.attributes(), try tp.type())
    }

    func parameterClause() throws -> ParameterClause {
        let pc = ParameterClause()
        if ts.test([.RightParenthesis]) {
            return pc
        }
        repeat {
            pc.body.append(try parameter())
        } while ts.test([.Comma])
        switch ts.look().kind {
        case .PrefixOperator("..."), .BinaryOperator("..."), .PostfixOperator("..."):
            ts.next()
            pc.isVariadic = true
        default:
            break
        }
        guard ts.test([.LeftParenthesis]) else {
            throw ParserError.Error("Expected ')' at the end of parameter.", ts.look().info)
        }
        return pc
    }

    private func parameter() throws -> Parameter {
        switch ts.look().kind {
        case .InOut, .Var, .Let, .Underscore:
            return try namedParameter()
        case .Atmark, .LeftBracket, .LeftParenthesis, .Protocol:
            return try unnamedParameter()
        case .Identifier:
            switch ts.look(1).kind {
            case .Underscore, .Identifier, .Colon:
                return try namedParameter()
            default:
                return try unnamedParameter()
            }
        default:
            throw ParserError.Error("Expected parameter.", ts.look().info)
        }
    }

    private func namedParameter() throws -> Parameter {
        let p = NamedParameter()
        if ts.test([.InOut]) {
            p.isInout = true
        }
        if case .Var = ts.match([.Var, .Let]) {
            p.isVariable = true
        }
        let name = try parameterName()
        let followName = try parameterName()
        switch name {
        case .Specified, .Needless:
            if case .NotSpecified = followName {
                p.externalName = .NotSpecified
                p.internalName = name
            } else {
                p.externalName = name
                p.internalName = followName
            }
        case .NotSpecified:
            throw ParserError.Error("Expected internal parameter name.", ts.look().info)
        }
        guard let a = try tp.typeAnnotation() else {
            throw ParserError.Error("Expected type annotation after parameter name.", ts.look().info)
        }
        p.type = a
        if ts.test([.AssignmentOperator]) {
            p.defaultArg = try ep.expression()
        }
        return .Named(p)
    }

    private func parameterName() throws -> ParameterName {
        switch ts.match([identifier, .Underscore]) {
        case let .Identifier(s):
            return .Specified(try createValueRef(s))
        case .Underscore:
            return .Needless
        default:
            return .NotSpecified
        }
    }

    private func unnamedParameter() throws -> Parameter {
        let a = try ap.attributes()
        return .Unnamed(a, try tp.type())
    }

    private func patternInitializerList() throws -> [(Pattern, Expression?)] {
        var pi: [(Pattern, Expression?)] = []
        repeat {
            let p = try ptp.declarationalPattern()
            if ts.test([.AssignmentOperator]) {
                pi.append((p, try ep.expression()))
            } else {
                pi.append((p, nil))
            }
        } while ts.test([.Comma])
        return pi
    }
}
