class DeclarationParser : GrammarParser {
    private var pp: PatternParser!
    private var ep: ExpressionParser!

    func setParser(
        patternParser pp: PatternParser, expressionParser ep: ExpressionParser
    ) {
        self.pp = pp
        self.ep = ep
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
