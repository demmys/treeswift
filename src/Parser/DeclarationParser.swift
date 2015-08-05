class DeclarationParser : GrammarParser {
    private var pp: PatternParser!
    private var ep: ExpressionParser!
    private var tp: TypeParser!
    private var ap: AttributesParser!

    func setParser(
        patternParser pp: PatternParser,
        expressionParser ep: ExpressionParser,
        typeParser tp: TypeParser,
        attributesParser ap: AttributesParser
    ) {
        self.pp = pp
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

    func variableDeclaration() throws -> VariableDeclaration {
        return .PatternInitializerList(try patternInitializerList())
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
            let p = try pp.declarationalPattern()
            if ts.test([.AssignmentOperator]) {
                pi.append((p, try ep.expression()))
            } else {
                pi.append((p, nil))
            }
        } while ts.test([.Comma])
        return pi
    }
}
