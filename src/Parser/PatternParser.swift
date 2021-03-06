import Util
import AST

enum ValueBindingStatus {
    case None, Variable, Constant
}

enum PatternUsage {
    case ConstantCreation, VariableCreation, VariableReference
}

class PatternParser : GrammarParser {
    private var tp: TypeParser!
    private var ep: ExpressionParser!

    func setParser(typeParser tp: TypeParser, expressionParser ep: ExpressionParser) {
        self.tp = tp
        self.ep = ep
    }

    func declarativePattern(usage: PatternUsage) throws -> Pattern {
        let info = ts.look().sourceInfo
        switch ts.match([.Underscore, .LeftParenthesis]) {
        case let .Identifier(s):
            switch ts.look(1).kind {
            case .Colon, .AssignmentOperator, .Comma, .RightParenthesis, .In:
                ts.next()
                return try identifierPattern(s, info, usage: usage)
            default:
                return ExpressionPattern(try ep.expression(.None))
            }
        case .Self:
            return ExpressionPattern(try ep.expression(.None))
        case .Underscore:
            return WildcardPattern()
        case .LeftParenthesis:
            return TuplePattern(try declarativeTuplePattern(usage))
        default:
            throw ts.fatal(.ExpectedDeclarativePattern)
        }
    }

    func conditionalPattern(valueBinding: ValueBindingStatus = .None) throws -> Pattern {
        return try containerPattern(try primaryPattern(valueBinding))
    }

    private func primaryPattern(valueBinding: ValueBindingStatus) throws -> Pattern {
        switch ts.match([
            .Underscore, .LeftParenthesis, .Var, .Let, .Is, .Dot
        ]) {
        case .Underscore:
            return WildcardPattern()
        case .LeftParenthesis:
            return TuplePattern(try conditionalTuplePattern(valueBinding))
        case .Var:
            if valueBinding != .None {
                throw ts.fatal(.NestedBindingPattern)
            }
            return VariableBindingPattern(try conditionalPattern(.Variable))
        case .Let:
            if valueBinding != .None {
                throw ts.fatal(.NestedBindingPattern)
            }
            return ConstantBindingPattern(try conditionalPattern(.Constant))
        case .Is:
            return TypePattern(try tp.type())
        case .Dot:
            let trackable = ts.look()
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedEnumCasePatternIdentifier)
            }
            let r = try ScopeManager.createEnumCaseRef(s, trackable)
            if ts.test([.LeftParenthesis]) {
                return EnumCasePattern(r, try conditionalTuplePattern(valueBinding))
            }
            return EnumCasePattern(r)
        case let .Identifier(s):
            let trackable = ts.look()
            if let m = testEnumCasePattern(s) {
                ts.next()
                return EnumCasePattern(
                    try ScopeManager.createEnumCaseRef(m, trackable, className: s),
                    try conditionalTuplePattern(valueBinding)
                )
            }
            fallthrough
        default:
            return ExpressionPattern(try ep.expression(valueBinding))
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

    private func identifierPattern(
        s: String, _ info: SourceInfo, usage: PatternUsage
    ) throws -> Pattern {
        switch usage {
        case .ConstantCreation:
            return ConstantIdentifierPattern(try ScopeManager.createConstant(s, info))
        case .VariableCreation:
            return VariableIdentifierPattern(try ScopeManager.createVariable(s, info))
        case .VariableReference:
            return ReferenceIdentifierPattern(try ScopeManager.createValueRef(s, info))
        }
    }

    private func declarativeTuplePattern(usage: PatternUsage) throws -> PatternTuple {
        return try tuplePattern({ try self.declarativePattern(usage) })
    }

    private func conditionalTuplePattern(
        valueBinding: ValueBindingStatus
    ) throws -> PatternTuple {
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
            return try containerPattern(OptionalPattern(p))
        case .As:
            let t = try tp.type()
            return try containerPattern(TypeCastingPattern(p, t))
        default:
            return p
        }
    }
}
