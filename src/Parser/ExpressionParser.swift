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

    func expression() throws -> Expression {
        let x = Expression()
        x.tryType = tryOperator()
        x.body = try expressionBody()
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

    private func expressionBody() throws -> ExpressionBody {
        let preExp = try expressionUnit()
        switch ts.match([binaryOperator, .BinaryQuestion, .Is, .As]) {
        case let .BinaryOperator(s):
            return try binaryExpressionBody(preExp, s)
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
        preExp: ExpressionUnit,
        _ s: String
    ) throws -> BinaryExpressionBody {
        let x = BinaryExpressionBody()
        x.left = preExp
        x.op = try getOperatorRef(s)
        x.right = try expressionBody()
        return x
    }

    private func conditionalExpressionBody(
        preExp: ExpressionUnit
    ) throws -> ConditionalExpressionBody {
        let x = ConditionalExpressionBody()
        x.cond = preExp
        x.trueSide = try expression()
        guard ts.test([.Colon]) else {
            throw ParserError.Error("Expected ':' after true condition of conditional expression", ts.look().info)
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

    private func expressionUnit() throws -> ExpressionUnit {
        let x = ExpressionUnit()
        x.pre = try expressionPrefix()
        x.core = try expressionCore()
        while let ep = try expressionPostfix() {
            x.posts.append(ep)
        }
        return x
    }

    private func expressionPrefix() throws -> ExpressionPrefix {
        switch ts.match([prefixOperator, .PrefixAmpersand]) {
        case let .PrefixOperator(s):
            return .Operator(try getOperatorRef(s))
        case .PrefixAmpersand:
            return .InOut
        default:
            return .Nothing
        }
    }

    private func expressionPostfix() throws -> ExpressionPostfix? {
        switch ts.match([
            postfixOperator, .LeftParenthesis, .Dot, .LeftBracket,
            .PostfixExclamation, .PostfixQuestion
        ]) {
        case let .PostfixOperator(s):
            return .Operator(try getOperatorRef(s))
        case .LeftParenthesis:
            // because of ambiguity, TreeSwift do not support a trailing closure
            return .FunctionCall(try tupleExpression())
        case .Dot:
            return try postfixMemberExpression()
        case .LeftBracket:
            let es = try expressionList()
            guard ts.test([.RightBracket]) else {
                throw ParserError.Error("Expected ']' at the end of subscript expression", ts.look().info)
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
            return .ExplicitNamedMember(
                try getMemberRef(s),
                genArgs: try gp.genericArgumentClause()
            )
        case .IntegerLiteral(let d, true):
            return .ExplicitUnnamedMember(try getMemberRef(Int(d)))
        default:
            throw ParserError.Error("Unexpected token after '.'", ts.look().info)
        }
    }

    private func expressionCore() throws -> ExpressionCore {
        switch ts.match([
            identifier, implicitParameterName, integerLiteral, floatingPointLiteral,
            stringLiteral, booleanLiteral, .Nil, .LeftBracket,
            .FILE, .LINE, .COLUMN, .FUNCTION,
            .`Self`, .Super, .LeftBrace, .LeftParenthesis, .Dot, .Underscore
        ]) {
        case let .Identifier(s):
            return .Value(
                try getValueRef(s),
                genArgs: try gp.genericArgumentClause()
            )
        case let .ImplicitParameterName(i):
            return .Value(
                try getImplicitParameterRef(i),
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
                throw ParserError.Error("Expected identifier after the begging of implicit member expression", ts.look().info)
            }
            return .ImplicitMember(try getMemberRef(s))
        case .Underscore:
            return .Wildcard
        default:
            throw ParserError.Error("Expected expression", ts.look().info)
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
            throw ParserError.Error("Parser reached end of file while parsing an array", ts.look().info)
        }
    }

    private func dictionaryLiteral() throws -> ExpressionCore {
        // empty dictionary
        if ts.test([.Colon]) {
            guard ts.test([.RightBracket]) else {
                throw ParserError.Error("Expected ']' at the end of dictionary literal", ts.look().info)
            }
            return .Dictionary([])
        }
        var es: [(Expression, Expression)] = []
        repeat {
            let key = try expression()
            guard ts.test([.Colon]) else {
                throw ParserError.Error("Expected ':' between the key and the value of dictionary literal", ts.look().info)
            }
            let value = try expression()
            es.append((key, value))
        } while ts.test([.Comma]) && ts.look().kind != .RightBracket
        guard ts.test([.RightBracket]) else {
            throw ParserError.Error("Expected ']' at the end of dictionary literal", ts.look().info)
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
        guard ts.test([.RightBracket]) else {
            throw ParserError.Error("Expected ']' at the end of array literal", ts.look().info)
        }
        return .Array(es)
    }

    private func selfExpression() throws -> ExpressionCore {
        switch ts.match([.Dot, .LeftBracket]) {
        case .Dot:
            switch ts.match([identifier, .Init]) {
            case let .Identifier(s):
                return .SelfMember(try getMemberRef(s))
            case .Init:
                return .SelfInitializer
            default:
                throw ParserError.Error("Expected member name or 'init' after dot", ts.look().info)
            }
        case .LeftBracket:
            let es = try expressionList()
            guard ts.test([.RightBracket]) else {
                throw ParserError.Error("Expected '[' at the end of subscript expression", ts.look().info)
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
                return .SuperClassMember(try getMemberRef(s))
            case .Init:
                return .SuperClassInitializer
            default:
                throw ParserError.Error("Expected member name or 'init' after dot", ts.look().info)
            }
        case .LeftBracket:
            let es = try expressionList()
            guard ts.test([.RightBracket]) else {
                throw ParserError.Error("Expected '[' at the end of subscript expression", ts.look().info)
            }
            return .SuperClassSubscript(es)
        default:
            throw ParserError.Error("Expected member expression or subscript expression after 'super'", ts.look().info)
        }
    }

    private func closureExpression() throws -> ExpressionCore {
        let c = Closure()
        switch ts.match([.LeftBracket]) {
        case .LeftBracket:
            try captureClause(c)
            switch ts.match([identifier]) {
            case .LeftParenthesis:
                c.params = .ExplicitTyped(try dp.parameterClause())
                c.returns = try dp.functionResult()
            case let .Identifier(s):
                c.params = try identifierList(s)
                c.returns = try dp.functionResult()
            default:
                break
            }
        case .LeftParenthesis:
            guard let i = findParenthesisClose(1) else {
                throw ParserError.Error("'(' not closed before end of file.", ts.look().info)
            }
            switch ts.look(i).kind {
            case .Arrow, .In:
                c.params = .ExplicitTyped(try dp.parameterClause())
                c.returns = try dp.functionResult()
            default:
                c.params = .NotProvided
                c.body = try closureExpressionTail()
                return .ClosureExpression(c)
            }
        case let .Identifier(s):
            switch ts.look().kind {
            case .Comma, .Arrow, .In:
                ts.next()
                c.params = try identifierList(s)
                c.returns = try dp.functionResult()
            default:
                c.body = try closureExpressionTail()
                return .ClosureExpression(c)
            }
        default:
            c.body = try closureExpressionTail()
            return .ClosureExpression(c)
        }
        guard ts.test([.In]) else {
            throw ParserError.Error("Expected 'in' after closure signature.", ts.look().info)
        }
        c.body = try closureExpressionTail()
        return .ClosureExpression(c)
    }

    private func identifierList(first: String) throws -> ClosureParameters {
        var list = [try createValueRef(first)]
        while ts.test([.Comma]) {
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ParserError.Error("Expected identifier after ',' of parameter list.", ts.look().info)
            }
            list.append(try createValueRef(s))
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
                    guard ts.test([.RightParenthesis]) else {
                        throw ParserError.Error("Expected ')' after 'safe' or 'unsafe' for unowned modifier", ts.look().info)
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

    private func closureExpressionTail() throws -> [Procedure] {
        let ps = try pp.procedures()
        guard ts.test([.RightBrace]) else {
            throw ParserError.Error("Expected '}' at the end of closure", ts.look().info)
        }
        return ps
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
                    throw ParserError.Error("Expected identifier for the label of tuple element", ts.look().info)
                }
                ts.next()
                t.append((s, try expression()))
                continue
            }
            t.append((nil, try expression()))
        } while ts.test([.Comma])
        guard ts.test([.RightParenthesis]) else {
            throw ParserError.Error("Expected ')' at the end of tuple", ts.look().info)
        }
        return t
    }
}
