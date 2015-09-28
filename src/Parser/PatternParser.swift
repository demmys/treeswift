class PatternParser : GrammarParser {
    private var tp: TypeParser!
    private var ep: ExpressionParser!

    func setParser(typeParser tp: TypeParser, expressionParser ep: ExpressionParser) {
        self.tp = tp
        self.ep = ep
    }

    func declarationalPattern() throws -> Pattern {
        switch ts.match([identifier, .Underscore, .LeftParenthesis]) {
        case let .Identifier(s):
            return try identifierPattern(s)
        case .Underscore:
            return try wildcardPattern()
        case .LeftParenthesis:
            return .TuplePattern(try declarationalTuplePattern())
        default:
            throw ts.fatal(.ExpectedDeclarationalPattern)
        }
    }

    func conditionalPattern() throws -> Pattern {
        return try containerPattern(try primaryPattern())
    }

    func primaryPattern() throws -> Pattern {
        switch ts.match([.Underscore, .LeftParenthesis, .Var, .Let, .Is, .Dot]) {
        case .Underscore:
            return try wildcardPattern()
        case .LeftParenthesis:
            return .TuplePattern(try conditionalTuplePattern())
        case .Var:
            return .VariableBindingPattern(try conditionalPattern())
        case .Let:
            return .ConstantBindingPattern(try conditionalPattern())
        case .Is:
            return .TypePattern(try tp.type())
        case .Dot:
            guard case let .Identifier(m) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedEnumCasePatternIdentifier)
            }
            return .EnumCasePattern(
                try getMemberRef(m), try conditionalTuplePattern()
            )
        case let .Identifier(s):
            if let m = testEnumCasePattern(s) {
                return .EnumCasePattern(
                    try getMemberRef(m, withClassName: s),
                    try conditionalTuplePattern()
                )
            }
            fallthrough
        default:
            return .ExpressionPattern(try ep.expression())
        }
    }

    func testEnumCasePattern(s: String) -> String? {
        guard isEnum(s), case .Dot = ts.look(1).kind else {
            return nil
        }
        guard case let .Identifier(s) = ts.look(2).kind else {
            return nil
        }
        ts.next(2)
        return s
    }

    func identifierPattern(s: String) throws -> Pattern {
        if let (type, attrs) = try tp.typeAnnotation() {
            return .TypedIdentifierPattern(try createValueRef(s), type, attrs)
        }
        return .IdentifierPattern(try createValueRef(s))
    }

    func wildcardPattern() throws -> Pattern {
        if let (type, attrs) = try tp.typeAnnotation() {
            return .TypedWildcardPattern(type, attrs)
        }
        return .WildcardPattern
    }

    func declarationalTuplePattern() throws -> PatternTuple {
        return try tuplePattern(declarationalTuplePattern)
    }

    func conditionalTuplePattern() throws -> PatternTuple {
        return try tuplePattern(conditionalTuplePattern)
    }

    func tuplePattern(
        patternParser: () throws -> PatternTuple
    ) throws -> PatternTuple {
        // unit
        if ts.test([.RightParenthesis]) {
            return []
        }
        var t: PatternTuple = []
        repeat {
            if case .Colon = ts.look(1).kind {
                guard case let .Identifier(s) = ts.match([identifier]) else {
                    throw ts.fatal(.ExpectedTupleLabel)
                }
                ts.next()
                t.append((s, .TuplePattern(try patternParser())))
                continue
            }
            t.append((nil, .TuplePattern(try patternParser())))
        } while ts.test([.Comma])
        if !ts.test([.RightParenthesis]) {
            try ts.error(.ExpectedRightParenthesisAfterTuple)
        }
        return t
    }

    func containerPattern(p: Pattern) throws -> Pattern {
        switch ts.match([.PostfixQuestion, .As]) {
        case .PostfixQuestion:
            return try containerPattern(.OptionalPattern(p))
        case .As:
            let t = try tp.type()
            return try containerPattern(.TypeCastingPattern(p, t))
        default:
            return p
        }
    }
}
