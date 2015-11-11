import Util
import AST

class ExpressionParser : GrammarParser {
    private var tp: TypeParser!
    private var gp: GenericsParser!
    private var pp: ProcedureParser!
    private var ep: ExpressionParser!
    private var dp: DeclarationParser!

    func setParser(
        typeParser tp: TypeParser,
        genericsParser gp: GenericsParser,
        procedureParser pp: ProcedureParser,
        expressionParser ep: ExpressionParser,
        declarationParser dp: DeclarationParser
    ) {
        self.tp = tp
        self.gp = gp
        self.pp = pp
        self.ep = ep
        self.dp = dp
    }

    func expressionList() throws -> [Expression] {
        var x: [Expression] = []
        repeat {
            x.append(try expression())
        } while ts.test([.Comma])
        return x
    }

    func expression(valueBinding: ValueBindingStatus = .None) throws -> Expression {
        let x = Expression()
        x.tryType = tryOperator()
        x.body = try expressionBody(valueBinding)
        return x
    }

    private func tryOperator() -> TryType {
        if ts.test([.Try]) {
            if ts.test([.PostfixExclamation]) {
                return .ForcedTry
            }
            return .Try
        }
        return .Nothing
    }

    private func expressionBody(
        valueBinding: ValueBindingStatus = .None
    ) throws -> ExpressionBody {
        let preExp = try expressionUnit(valueBinding)
        let trackable = ts.look()
        switch ts.match([binaryOperator, .BinaryQuestion, .Is, .As]) {
        case let .BinaryOperator(s):
            return try binaryExpressionBody(
                preExp, s, trackable, valueBinding: valueBinding
            )
        case .BinaryQuestion:
            return try conditionalExpressionBody(preExp)
        case .Is:
            return try isTypeCastingExpressionBody(preExp)
        case .As:
            return try asTypeCastingExpressionBody(preExp)
        default:
            let x = ExpressionBody()
            x.unit = preExp
            return x
        }
    }

    private func binaryExpressionBody(
        preExp: ExpressionUnit, _ s: String, _ trackable: SourceTrackable,
        valueBinding: ValueBindingStatus
    ) throws -> BinaryExpressionBody {
        let x = BinaryExpressionBody()
        x.left = preExp
        x.op = try ScopeManager.createOperatorRef(s, trackable)
        x.right = try expressionBody(valueBinding)
        return x
    }

    private func conditionalExpressionBody(
        preExp: ExpressionUnit
    ) throws -> ConditionalExpressionBody {
        let x = ConditionalExpressionBody()
        x.cond = preExp
        x.trueSide = try expression()
        if !ts.test([.Colon]) {
            try ts.error(.ExpectedColonAfterCondition)
        }
        x.falseSide = try expression()
        return x
    }

    private func isTypeCastingExpressionBody(
        preExp: ExpressionUnit
    ) throws -> TypeCastingExpressionBody {
        let x = TypeCastingExpressionBody()
        x.left = preExp
        x.castType = .Is
        x.type = try tp.type()
        return x
    }

    private func asTypeCastingExpressionBody(
        preExp: ExpressionUnit
    ) throws -> TypeCastingExpressionBody {
        let x = TypeCastingExpressionBody()
        x.left = preExp
        switch ts.match([.PostfixQuestion, .PostfixExclamation]) {
        case .PostfixQuestion:
            x.castType = .ConditionalAs
        case .PostfixExclamation:
            x.castType = .ForcedAs
        default:
            x.castType = .As
        }
        x.type = try tp.type()
        return x
    }

    private func expressionUnit(
        valueBinding: ValueBindingStatus
    ) throws -> ExpressionUnit {
        let x = ExpressionUnit()
        x.pre = try expressionPrefix()
        x.core = try expressionCore(valueBinding)
        while let ep = try expressionPostfix() {
            x.posts.append(ep)
        }
        return x
    }

    private func expressionPrefix() throws -> ExpressionPrefix {
        let trackable = ts.look()
        switch ts.match([prefixOperator, .PrefixAmpersand]) {
        case let .PrefixOperator(s):
            return .Operator(try ScopeManager.createOperatorRef(s, trackable))
        case .PrefixAmpersand:
            return .InOut
        default:
            return .Nothing
        }
    }

    private func expressionPostfix() throws -> ExpressionPostfix? {
        let trackable = ts.look()
        switch ts.match([
            postfixOperator, .LeftParenthesis, .Dot, .LeftBracket,
            .PostfixExclamation, .PostfixQuestion
        ]) {
        case let .PostfixOperator(s):
            return .Operator(try ScopeManager.createOperatorRef(s, trackable))
        case .LeftParenthesis:
            // because of ambiguity, TreeSwift do not support a trailing closure
            return .FunctionCall(try tupleExpression())
        case .Dot:
            return try postfixMemberExpression()
        case .LeftBracket:
            let es = try expressionList()
            if !ts.test([.RightBracket]) {
                try ts.error(.ExpectedRightBracketAfterSubscript)
            }
            return .Subscript(es)
        case .PostfixExclamation:
            return .ForcedValue
        case .PostfixQuestion:
            return .OptionalChaining
        default:
            return nil
        }
    }

    private func postfixMemberExpression() throws -> ExpressionPostfix {
        switch ts.match([.Init, .`Self`, .DynamicType, identifier, integerLiteral]) {
        case .Init:
            return .Initializer
        case .`Self`:
            return .PostfixSelf
        case .DynamicType:
            return .DynamicType
        case let .Identifier(s):
            return .ExplicitNamedMember(s, genArgs: try gp.genericArgumentClause())
        case .IntegerLiteral(let d, true):
            return .ExplicitUnnamedMember(d)
        default:
            throw ts.fatal(.UnexpectedTokenForMember)
        }
    }

    private func expressionCore(
        valueBinding: ValueBindingStatus
    ) throws -> ExpressionCore {
        let trackable = ts.look()
        switch ts.match([
            identifier, binaryOperator, implicitParameterName, integerLiteral,
            floatingPointLiteral, stringLiteral, booleanLiteral, .Nil, .LeftBracket,
            .FILE, .LINE, .COLUMN, .FUNCTION,
            .`Self`, .Super, .LeftBrace, .LeftParenthesis, .Dot, .Underscore
        ]) {
        case let .Identifier(s):
            switch valueBinding {
            case .None:
                return .Value(
                    try ScopeManager.createValueRef(s, trackable),
                    genArgs: try gp.genericArgumentClause()
                )
            case .Constant:
                return .BindingConstant(
                    try ScopeManager.createConstant(s, trackable)
                )
            case .Variable:
                return .BindingVariable(
                    try ScopeManager.createVariable(s, trackable)
                )
            }
        case let .BinaryOperator(s):
            switch valueBinding {
            case .None:
                return .Value(
                    try ScopeManager.createValueRef(s, trackable),
                    genArgs: try gp.genericArgumentClause()
                )
            case .Constant:
                return .BindingConstant(
                    try ScopeManager.createConstant(s, trackable)
                )
            case .Variable:
                return .BindingVariable(
                    try ScopeManager.createVariable(s, trackable)
                )
            }
        case let .ImplicitParameterName(i):
            return .ImplicitParameter(
                try ScopeManager.createImplicitParameterRef(i, trackable),
                genArgs: try gp.genericArgumentClause()
            )
        case let .IntegerLiteral(i, _):
            return .Integer(i)
        case let .FloatingPointLiteral(f):
            return .FloatingPoint(f)
        case let .StringLiteral(s):
            return .StringExpression(s)
        case let .BooleanLiteral(b):
            return .Boolean(b)
        case .Nil:
            return .Nil
        case .LeftBracket:
            return try correctionLiteral()
        case .FILE:
            return .StringExpression("")// currentFileName()) TODO
        case .LINE:
            return .Integer(0)// currentLineNumber()) TODO
        case .COLUMN:
            return .Integer(0)// currentColumnNumber()) TODO
        case .FUNCTION:
            return .StringExpression("")// currentFunctionName()) TODO
        case .`Self`:
            return try selfExpression()
        case .Super:
            return try superClassExpression()
        case .LeftBrace:
            return try closureExpression()
        case .LeftParenthesis:
            return .TupleExpression(try tupleExpression())
        case .Dot:
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedImplicitMember)
            }
            return .ImplicitMember(s)
        case .Underscore:
            return .Wildcard
        default:
            throw ts.fatal(.ExpectedExpression)
        }
    }

    private func correctionLiteral() throws -> ExpressionCore {
        let (_, k) = findInsideOfBrackets([TokenKind.Colon])
        switch k {
        case .Colon:
            return try dictionaryLiteral()
        case .RightBracket:
            return try arrayLiteral()
        default:
            throw ts.fatal(.UnexpectedEOFWhileArray)
        }
    }

    private func dictionaryLiteral() throws -> ExpressionCore {
        // empty dictionary
        if ts.test([.Colon]) {
            if !ts.test([.RightBracket]) {
                try ts.error(.ExpectedRightBracketAfterDictionary)
            }
            return .Dictionary([])
        }
        var es: [(Expression, Expression)] = []
        repeat {
            let key = try expression()
            if !ts.test([.Colon]) {
                try ts.error(.ExpectedColonForDictionary)
            }
            let value = try expression()
            es.append((key, value))
        } while ts.test([.Comma]) && ts.look().kind != .RightBracket
        if !ts.test([.RightBracket]) {
            try ts.error(.ExpectedRightBracketAfterDictionary)
        }
        return .Dictionary(es)
    }

    private func arrayLiteral() throws -> ExpressionCore {
        // empty array
        if ts.test([.RightBracket]) {
            return .Array([])
        }
        var es: [Expression] = []
        repeat {
            es.append(try expression())
        } while ts.test([.Comma]) && ts.look().kind != .RightBracket
        if !ts.test([.RightBracket]) {
            try ts.error(.ExpectedRightBracketAfterArray)
        }
        return .Array(es)
    }

    private func selfExpression() throws -> ExpressionCore {
        switch ts.match([.Dot, .LeftBracket]) {
        case .Dot:
            switch ts.match([identifier, .Init]) {
            case let .Identifier(s):
                return .SelfMember(s)
            case .Init:
                return .SelfInitializer
            default:
                throw ts.fatal(.ExpectedMember)
            }
        case .LeftBracket:
            let es = try expressionList()
            if !ts.test([.RightBracket]) {
                try ts.error(.ExpectedRightBracketAfterSubscript)
            }
            return .SelfSubscript(es)
        default:
            return .SelfExpression
        }
    }

    private func superClassExpression() throws -> ExpressionCore {
        switch ts.match([.Dot, .LeftBracket]) {
        case .Dot:
            switch ts.match([identifier, .Init]) {
            case let .Identifier(s):
                return .SuperClassMember(s)
            case .Init:
                return .SuperClassInitializer
            default:
                throw ts.fatal(.ExpectedMember)
            }
        case .LeftBracket:
            let es = try expressionList()
            if !ts.test([.RightBracket]) {
                try ts.error(.ExpectedRightBracketAfterSubscript)
            }
            return .SuperClassSubscript(es)
        default:
            throw ts.fatal(.ExpectedSuperMember)
        }
    }

    private func closureExpression() throws -> ExpressionCore {
        ScopeManager.enterScope(.Closure)
        let c = Closure()
        switch ts.match([.LeftBracket]) {
        case .LeftBracket:
            try captureClause(c)
            let info = ts.look().sourceInfo
            switch ts.match([identifier]) {
            case .LeftParenthesis:
                c.params = .ExplicitTyped(try dp.parameterClause(false))
                c.returns = try dp.functionResult()
            case let .Identifier(s):
                c.params = try identifierList(s, info)
                c.returns = try dp.functionResult()
            default:
                break
            }
        case .LeftParenthesis:
            guard let i = findParenthesisClose(1) else {
                throw ts.fatal(.NotClosedLeftParenthesis)
            }
            switch ts.look(i + 1).kind {
            case .Arrow, .In:
                c.params = .ExplicitTyped(try dp.parameterClause(false))
                c.returns = try dp.functionResult()
            default:
                c.params = .NotProvided
            }
        case let .Identifier(s):
            let info = ts.look().sourceInfo
            switch ts.look().kind {
            case .Comma, .Arrow, .In:
                ts.next()
                c.params = try identifierList(s, info)
                c.returns = try dp.functionResult()
            default:
                break
            }
        default:
            break
        }
        if !ts.test([.In]) {
            try ts.error(.ExpectedInForClosureSignature)
        }
        return try closureExpressionTail(c)
    }

    private func identifierList(
        first: String, _ info: SourceInfo
    ) throws -> ClosureParameters {
        var list = [try ScopeManager.createConstant(first, info)]
        while ts.test([.Comma]) {
            let trackable = ts.look()
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedParameterName)
            }
            list.append(try ScopeManager.createConstant(s, trackable))
        }
        return .ImplicitTyped(list)
    }

    private func captureClause(c: Closure) throws {
        repeat {
            var s: CaptureSpecifier!
            specifierSwitch: switch ts.match([modifier]) {
            case .Modifier(.Weak):
                s = .Weak
            case .Modifier(.Unowned):
                if case .LeftParenthesis = ts.look().kind {
                    switch ts.match([.Safe, .Unsafe], ahead: 1) {
                    case .Safe:
                        s = .UnownedSafe
                    case .Unsafe:
                        s = .UnownedUnsafe
                    default:
                        s = .Unowned
                        break specifierSwitch
                    }
                    if !ts.test([.RightParenthesis]) {
                        try ts.error(.ExpectedUnownedSafeUnsafeModifierRightParenthesis)
                    }
                } else {
                    s = .Unowned
                }
            default:
                s = .Nothing
            }
            let e = try ep.expression()
            c.caps.append((s, e))
        } while ts.test([.Comma])
    }

    private func closureExpressionTail(c: Closure) throws -> ExpressionCore {
        c.body = try pp.procedures()
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterClosure)
        }
        c.associatedScope = try ScopeManager.leaveScope(.Closure, ts.look())
        return .ClosureExpression(c)
    }

    private func tupleExpression() throws -> Tuple {
        // unit
        if ts.test([.RightParenthesis]) {
            return []
        }
        var t: Tuple = []
        repeat {
            if case .Colon = ts.look(1).kind {
                guard case let .Identifier(s) = ts.match([identifier]) else {
                    throw ts.fatal(.ExpectedTupleLabel)
                }
                ts.next()
                t.append((s, try expression()))
                continue
            }
            t.append((nil, try expression()))
        } while ts.test([.Comma])
        if !ts.test([.RightParenthesis]) {
            try ts.error(.ExpectedRightParenthesisAfterTuple)
        }
        return t
    }
}
