import Util
import AST

class PatternParser : GrammarParser {
    private var tp: TypeParser!
    private var ep: ExpressionParser!

    func setParser(typeParser tp: TypeParser, expressionParser ep: ExpressionParser) {
        self.tp = tp
        self.ep = ep
    }

    func declarationalPattern() throws -> Pattern {
        let info = ts.look().sourceInfo
        switch ts.match([identifier, .Underscore, .LeftParenthesis]) {
        case let .Identifier(s):
            return try identifierPattern(s, info)
        case .Underscore:
            return try wildcardPattern()
        case .LeftParenthesis:
            return .TuplePattern(try declarationalTuplePattern())
        default:
            throw ts.fatal(.ExpectedDeclarationalPattern)
        }
    }

    func conditionalPattern(valueBinding: Bool = false) throws -> Pattern {
        return try containerPattern(try primaryPattern(valueBinding))
    }

    private func primaryPattern(valueBinding: Bool) throws -> Pattern {
        switch ts.match([.Underscore, .LeftParenthesis, .Var, .Let, .Is, .Dot]) {
        case .Underscore:
            return try wildcardPattern()
        case .LeftParenthesis:
            return .TuplePattern(try conditionalTuplePattern(true))
        case .Var:
            if valueBinding {
                throw ts.fatal(.NestedBindingPattern)
            }
            return .VariableBindingPattern(try conditionalPattern(true))
        case .Let:
            if valueBinding {
                throw ts.fatal(.NestedBindingPattern)
            }
            return .ConstantBindingPattern(try conditionalPattern(true))
        case .Is:
            return .TypePattern(try tp.type())
        case .Dot:
            guard case let .Identifier(m) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedEnumCasePatternIdentifier)
            }
            return .EnumCasePattern(
                try getMemberRef(m), try conditionalTuplePattern(true)
            )
        case let .Identifier(s):
            if let m = testEnumCasePattern(s) {
                return .EnumCasePattern(
                    try getMemberRef(m, withClassName: s),
                    try conditionalTuplePattern(true)
                )
            }
            fallthrough
        default:
            return .ExpressionPattern(try ep.expression(true))
        }
    }

    private func testEnumCasePattern(s: String) -> String? {
        guard isEnum(s), case .Dot = ts.look(1).kind else {
            return nil
        }
        guard case let .Identifier(s) = ts.look(2).kind else {
            return nil
        }
        ts.next(2)
        return s
    }

    private func identifierPattern(s: String, _ info: SourceInfo) throws -> Pattern {
        if let (type, attrs) = try tp.typeAnnotation() {
            return .TypedIdentifierPattern(try ScopeManager.createValue(s, info), type, attrs)
        }
        return .IdentifierPattern(try ScopeManager.createValue(s, info))
    }

    private func wildcardPattern() throws -> Pattern {
        if let (type, attrs) = try tp.typeAnnotation() {
            return .TypedWildcardPattern(type, attrs)
        }
        return .WildcardPattern
    }

    private func declarationalTuplePattern() throws -> PatternTuple {
        return try tuplePattern(declarationalPattern)
    }

    private func conditionalTuplePattern(valueBinding: Bool) throws -> PatternTuple {
        return try tuplePattern({ try self.conditionalPattern(valueBinding) })
    }

    private func tuplePattern(
        patternParser: () throws -> Pattern
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
                t.append((s, try patternParser()))
                continue
            }
            t.append((nil, try patternParser()))
        } while ts.test([.Comma])
        if !ts.test([.RightParenthesis]) {
            try ts.error(.ExpectedRightParenthesisAfterTuple)
        }
        return t
    }

    private func containerPattern(p: Pattern) throws -> Pattern {
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
