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
        let attrs = try ap.attributes()
        let almod = try ap.accessLevelModifier()
        var mods = try ap.declarationModifiers()
        switch ts.match([
            .Import, .Let, .Var, .Typealias, .Func, .Indirect, .Enum,
            .Struct, .Class, .Protocol, .Init, .Deinit, .Extension, .Subscript,
            .Prefix, .Postfix, .Infix
        ]) {
        case .Import:
            if almod != nil || mods.count > 0 {
                throw ParserError.Error("Unexpected modifier before 'import'.", ts.look().info)
            }
            return try importDeclaration(attrs)
        case .Let:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try constantDeclaration(attrs, mods)
        case .Var:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try variableDeclaration(attrs, mods)
        case .Typealias:
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'typealias'.", ts.look().info)
            }
            return try typealiasDeclaration(attrs, almod)
        case .Func:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try functionDeclaration(attrs, mods)
        case .Indirect:
            guard ts.test([.Enum]) else {
                throw ParserError.Error("Expected enum declaration after 'indirect'.", ts.look().info)
            }
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'enum'.", ts.look().info)
            }
            return try enumDeclaration(attrs, almod, isIndirect: true)
        case .Enum:
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'enum'.", ts.look().info)
            }
            return try enumDeclaration(attrs, almod)
        case .Struct:
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'struct'.", ts.look().info)
            }
            return try structDeclaration(attrs, almod)
        case .Class:
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'class'.", ts.look().info)
            }
            return try classDeclaration(attrs, almod)
        case .Protocol:
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'protocol'.", ts.look().info)
            }
            return try protocolDeclaration(attrs, almod)
        case .Init:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try initializerDeclaration(attrs, mods)
        case .Deinit:
            if almod != nil || mods.count > 0 {
                throw ParserError.Error("Unexpected modifier before 'deinit'.", ts.look().info)
            }
            return try deinitializerDeclaration(attrs)
        case .Extension:
            if attrs.count > 0 {
                throw ParserError.Error("Unexpected attribute before 'extension'.", ts.look().info)
            }
            if mods.count > 0 {
                throw ParserError.Error("Unexpected declaration modifier before 'extension'.", ts.look().info)
            }
            return try extensionDeclaration(almod)
        case .Subscript:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try subscriptDeclaration(attrs, mods)
        case .Prefix:
            if attrs.count > 0 {
                throw ParserError.Error("Unexpected attribute before operator declaration 'prefix'.", ts.look().info)
            }
            if almod != nil || mods.count > 0 {
                throw ParserError.Error("Unexpected modifier before operator declaration 'prefix'.", ts.look().info)
            }
            return try operatorDeclaration(.Prefix)
        case .Postfix:
            if attrs.count > 0 {
                throw ParserError.Error("Unexpected attribute before operator declaration 'postfix'.", ts.look().info)
            }
            if almod != nil || mods.count > 0 {
                throw ParserError.Error("Unexpected modifier before operator declaration 'postfix'.", ts.look().info)
            }
            return try operatorDeclaration(.Postfix)
        case .Infix:
            if attrs.count > 0 {
                throw ParserError.Error("Unexpected attribute before operator declaration 'infix'.", ts.look().info)
            }
            if almod != nil || mods.count > 0 {
                throw ParserError.Error("Unexpected modifier before operator declaration 'infix'.", ts.look().info)
            }
            return try infixOperatorDeclaration()
        default:
            throw ParserError.Error("Expected declaration.", ts.look().info)
        }
    }

    func typeInheritanceClause() throws -> TypeInheritanceClause? {
        guard ts.test([.Colon]) else {
            return nil
        }
        let x = TypeInheritanceClause()
        if ts.test([.Class]) {
            x.classRequirement = true
            guard ts.test([.Comma]) else {
                return x
            }
        }
        repeat {
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ParserError.Error("Expected identifier for type name.", ts.look().info)
            }
            x.types.append(try tp.identifierType(s))
        } while ts.test([.Comma])
        return x
    }

    private func importDeclaration(attrs: [Attribute]) throws -> ImportDeclaration {
        let x = ImportDeclaration(attrs)
        switch ts.match([
            .Typealias, .Struct, .Class, .Enum, .Protocol, .Var, .Func
        ]) {
        case .Typealias: x.kind = .Typealias
        case .Struct: x.kind = .Struct
        case .Class: x.kind = .Class
        case .Enum: x.kind = .Enum
        case .Protocol: x.kind = .Protocol
        case .Var: x.kind = .Var
        case .Func: x.kind = .Func
        default: break
        }
        repeat {
            switch ts.match([
                identifier, prefixOperator, binaryOperator, postfixOperator
            ]) {
            case let .Identifier(s): x.path.append(s)
            case let .PrefixOperator(s): x.path.append(s)
            case let .BinaryOperator(s): x.path.append(s)
            case let .PostfixOperator(s): x.path.append(s)
            default:
                throw ParserError.Error("Expected path to import.", ts.look().info)
            }
        } while ts.test([.Dot])
        return x
    }

    private func constantDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> PatternInitializerDeclaration {
        return PatternInitializerDeclaration(
            attrs, mods, isVariable: false, inits: try patternInitializerList()
        )
    }

    func variableDeclaration(
        attrs: [Attribute] = [], _ mods: [Modifier] = []
    ) throws -> Declaration {
        switch ts.look().kind {
        case .Underscore, .LeftParenthesis:
            return PatternInitializerDeclaration(
                attrs, mods, isVariable: true, inits: try patternInitializerList()
            )
        case .Identifier:
            let inits = try patternInitializerList()
            if ts.test([.LeftBrace]) {
                guard inits.count == 1 else {
                    throw ParserError.Error("When the variable has blocks, you can define only one variable in a declaration.", ts.look().info)
                }
                return try variableBlockDeclaration(attrs, mods, ini: inits[0])
            }
            return PatternInitializerDeclaration(
                attrs, mods, isVariable: true, inits: inits
            )
        default:
            throw ParserError.Error("Expected identifier or declarational pattern for variable declaration.", ts.look().info)
        }
    }

    func variableBlockDeclaration(
        attrs: [Attribute], _ mods: [Modifier], ini: (Pattern, Expression?)
    ) throws -> VariableBlockDeclaration {
        switch ini.0 {
        case let .IdentifierPattern(r):
            guard let e = ini.1 else {
                throw ParserError.Error("Expected type annotation or initializer for variable declaration with block.", ts.look().info)
            }
            let x = VariableBlockDeclaration(attrs, mods, name: r)
            x.specifier = .Initializer(e)
            x.blocks = try willSetDidSetBlock()
            return x
        case let .TypedIdentifierPattern(r, t, attrs):
            let x = VariableBlockDeclaration(attrs, mods, name: r)
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
        var x: VariableBlocks!
        switch ts.match([.Get, .Set], ahead: ahead) {
        case .Get:
            switch ts.match([.Set]) {
            case .Set:
                x = .GetterSetterKeyword(getAttrs: attrs, setAttrs: [])
            case .Atmark:
                let setAttrs = try ap.attributes()
                guard ts.test([.Set]) else {
                    throw ParserError.Error("Expected setter keywork after 'get'", ts.look().info)
                }
                x = .GetterSetterKeyword(getAttrs: attrs, setAttrs: setAttrs)
            case .RightBrace:
                x = .GetterKeyword(attrs)
            default:
                let g = VariableBlock(attrs)
                g.body = try prp.proceduresBlock()
                if ts.test([.RightBrace]) {
                    x = .GetterSetter(getter: g, setter: nil)
                } else {
                    let setAttrs = try ap.attributes()
                    guard ts.test([.Set]) else {
                        throw ParserError.Error("Expected setter clause after getter clause", ts.look().info)
                    }
                    let s = try setterBlock(setAttrs)
                    x = .GetterSetter(getter: g, setter: s)
                }
            }
        case .Set:
            switch ts.match([.Get]) {
            case .Get:
                x = .GetterSetterKeyword(getAttrs: [], setAttrs: attrs)
            case .Atmark:
                let getAttrs = try ap.attributes()
                guard ts.test([.Get]) else {
                    throw ParserError.Error("Expected getter keywork after 'set'", ts.look().info)
                }
                x = .GetterSetterKeyword(getAttrs: getAttrs, setAttrs: attrs)
            default:
                let s = try setterBlock(attrs)
                let getAttrs = try ap.attributes()
                guard ts.test([.Get]) else {
                    throw ParserError.Error("Expected getter clause after setter clause.", ts.look().info)
                }
                let g = VariableBlock(getAttrs)
                g.body = try prp.proceduresBlock()
                x = .GetterSetter(getter: g, setter: s)
            }
        case .Atmark:
            // Expect getter, setter or procedure beggining with attributes
            // To avoid consuming attributes for procedure, use TokenStream.look only
            let (firstAttrs, i) = try ap.lookAfterAttributes()
            switch ts.look(i).kind {
            case .Get, .Set: x = try getterSetterBlock(firstAttrs, ahead: i)
            default: break
            }
            fallthrough
        default:
            let g = VariableBlock()
            g.body = try prp.procedures()
            x = .GetterSetter(getter: g, setter: nil)
        }
        guard ts.test([.RightBrace]) else {
            throw ParserError.Error("Expected '}' at the end of variable block clause", ts.look().info)
        }
        return x
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

    private func typealiasDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> TypealiasDeclaration {
        let x = TypealiasDeclaration(attrs, mod)
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ParserError.Error("Expected identifier for typealias name.", ts.look().info)
        }
        x.name = try createTypeRef(s)
        x.inherits = try typeInheritanceClause()
        x.type = try tp.type()
        if x.inherits != nil {
            x.forProtocol = true
        }
        if ts.test([.AssignmentOperator]) {
            x.type = try tp.type()
        } else {
            x.forProtocol = true
        }
        return x
    }

    private func functionDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> FunctionDeclaration {
        throw ParserError.Error("FunctionDeclaration parser is not implemented yet.", ts.look().info)
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

    private func enumDeclaration(
        attrs: [Attribute], _ mod: Modifier?, isIndirect: Bool = true
    ) throws -> EnumDeclaration {
        throw ParserError.Error("EnumDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func structDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> StructDeclaration {
        throw ParserError.Error("StructDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func classDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> ClassDeclaration {
        throw ParserError.Error("ClassDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func protocolDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> ProtocolDeclaration {
        throw ParserError.Error("ProtocolDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func initializerDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> InitializerDeclaration {
        throw ParserError.Error("InitializerDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func deinitializerDeclaration(
        attrs: [Attribute]
    ) throws -> DeinitializerDeclaration {
        throw ParserError.Error("DeinitializerDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func extensionDeclaration(mod: Modifier?) throws -> ExtensionDeclaration {
        throw ParserError.Error("ExtensionDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func subscriptDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> SubscriptDeclaration {
        throw ParserError.Error("SubscriptDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func operatorDeclaration(
        kind: OperatorDeclarationKind
    ) throws -> OperatorDeclaration {
        throw ParserError.Error("OperatorDeclaration parser is not implemented yet.", ts.look().info)
    }

    private func infixOperatorDeclaration() throws -> OperatorDeclaration {
        throw ParserError.Error("InfixOperatorDeclaration parser is not implemented yet.", ts.look().info)
    }
}
