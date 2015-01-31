import Util

public enum ParseResult {
    case Success(AST)
    case Failure([Error])
}

private let identifier = TokenKind.Identifier(.Identifier(""))
private let integerLiteral = TokenKind.IntegerLiteral(0, decimalDigits: false)
private let booleanLiteral = TokenKind.BooleanLiteral(true)
private let prefixOperator = TokenKind.PrefixOperator("")
private let postfixOperator = TokenKind.PostfixOperator("")
private let binaryOperator = TokenKind.BinaryOperator("")

private func findDFA(tp: TokenPeeper,
                     rules: [(TokenKind, Void -> [Symbol]?)],
                     startIndex: Int = 0) -> [Symbol]? {
    var i = startIndex
    var kind = tp.look(i).kind
    while kind != .EndOfFile {
        for (target, generator) in rules {
            if kind == target {
                return generator()
            }
        }
        kind = tp.look(++i).kind
    }
    return nil
}

protocol Symbol {
    func parse(TokenStream) -> ParseResult
}

class TerminalSymbol : Symbol {
    private let kinds: [TokenKind]
    private var errorGenerator: (SourceInfo -> [Error])?
    private var isOptional: Bool
    private var skipLineFeed: Bool

    init(_ kinds: [TokenKind],
         errorGenerator: (SourceInfo -> [Error])? = nil,
         isOptional: Bool = false,
         skipLineFeed: Bool = true) {
        self.kinds = kinds
        self.errorGenerator = errorGenerator
        self.isOptional = isOptional
        self.skipLineFeed = skipLineFeed
    }

    func parse(input: TokenStream) -> ParseResult {
        var inputToken = input.look(0, skipLineFeed: false)
        switch inputToken.kind {
        case let .Error(e):
            return .Failure([(e, inputToken.info)])
        case .LineFeed:
            for kind in kinds {
                if kind == .LineFeed {
                    input.next()
                    return .Success(generateAST(inputToken))
                } else if self.skipLineFeed {
                    inputToken = input.look(1)
                    if kind == inputToken.kind {
                        input.next(n: 2)
                        return .Success(generateAST(inputToken))
                    }
                }
            }
        default:
            for kind in kinds {
                if inputToken.kind == kind {
                    input.next()
                    return .Success(generateAST(inputToken))
                }
            }
        }
        if isOptional {
            return .Success(OptionalParts())
        }

        if let eg = errorGenerator {
            return .Failure(eg(inputToken.info))
        }
        assert(false, "Unexpected syntax error")
    }

    func generateAST(token: Token) -> AST {
        switch token.kind {
        case let .Identifier(k):
            return Identifier(k)
        case let .IntegerLiteral(n, _):
            return IntegerLiteral(n)
        case let .BooleanLiteral(b):
            if b {
                return LiteralExpression.True
            }
            return LiteralExpression.False
        case .Nil:
            return LiteralExpression.Nil
        case .Weak:
            return CaptureSpecifier.Weak
        case .Unowned:
            return CaptureSpecifier.Unowned
        case let .PostfixOperator(s):
            return PostfixOperator(s)
        case let .PrefixOperator(s):
            return PrefixOperator(s)
        case let .BinaryOperator(s):
            return BinaryOperator(s)
        case .AssignmentOperator:
            return AssignmentOperator()
        case .Is:
            return TypeCastingOperator.Is
        case .As:
            return TypeCastingOperator.As
        case .Inout:
            return Inout()
        case .Var:
            return ValueClass.Var
        case .Let:
            return ValueClass.Let
        case .Underscore:
            return Underscore()
        case .Left:
            return Associativity.Left
        case .Right:
            return Associativity.Right
        case .None:
            return Associativity.None
        case .Hash:
            return Hash()
        default:
            return Terminal()
        }
    }
}

class NonTerminalSymbol : Symbol {
    private var ruleArbiter: TokenPeeper -> [Symbol]?
    private var isOptional: Bool

    /*
     * `ruleArbiter` is DFA, which decides the rule that will be applied or
     * returns nil when there's no rule to apply to.
     * `astGenerator` generates Abstruct Syntax Tree of this symbol from
     * parse result.
     */
    init(_ ruleArbiter: TokenPeeper -> [Symbol]?, isOptional: Bool = false) {
        self.ruleArbiter = ruleArbiter
        self.isOptional = isOptional
    }

    func parse(input: TokenStream) -> ParseResult {
        switch input.look().kind {
        case let .Error(e):
            return .Failure([(e, input.look().info)])
        default:
            break
        }
        var errors: [Error] = []
        var asts: [AST] = []
        if let elements = ruleArbiter(input) {
            for element in elements {
                switch element.parse(input) {
                case let .Success(ast):
                    asts.append(ast)
                case let .Failure(es):
                    errors.extend(es)
                }
            }
            if errors.count > 0 {
                return .Failure(errors)
            } else {
                return .Success(generateAST(asts))
            }
        } else if isOptional {
            return .Success(OptionalParts())
        }
        return .Failure([(.UnexpectedSymbol, input.look().info)])
    }

    func generateAST(asts: [AST]) -> AST {
        assert(false, "Unimplemented AST generation")
    }
}

/*
 * Literals
 */
class LiteralSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .IntegerLiteral:
                return [TerminalSymbol([integerLiteral])]
            case .BooleanLiteral:
                return [TerminalSymbol([booleanLiteral])]
            case .Nil:
                return [TerminalSymbol([.Nil])]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let i as IntegerLiteral:
            return LiteralExpression.Integer(i.value)
        default:
            return asts[0]
        }
    }
}

/*
 * Expressions
 */
class WildcardExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Underscore])] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return PrimaryExpression.Whildcard
    }
}

class ExpressionElementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look(1).kind != .Colon {
                return [ExpressionSymbol()]
            }
            return [
                TerminalSymbol([identifier]),
                TerminalSymbol([.Colon]),
                ExpressionSymbol()
            ]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count > 1 {
            return ExpressionElement.Named(
                (asts[0] as Identifier).value,
                asts[2] as Expression
            )
        }
        return ExpressionElement.Unnamed(asts[0] as Expression)
    }
}

class ExpressionElementListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .Comma {
                return nil
            }
            return [
                TerminalSymbol([.Comma]),
                ExpressionElementListSymbol()
            ]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class ExpressionElementListSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .RightParenthesis {
                return nil
            }
            return [
                ExpressionElementSymbol(),
                ExpressionElementListTailSymbol(isOptional: true)
            ]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        var head = asts[0] as ExpressionElement
        if let tail = asts[1] as? ExpressionElements {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return ExpressionElements([head])
    }
}

class ParenthesizedExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftParenthesis]),
            ExpressionElementListSymbol(isOptional: true),
            TerminalSymbol([.RightParenthesis],
                           errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class CaptureSpecifierSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .Weak:
                return [TerminalSymbol([.Weak])]
            case .Unowned:
                return [TerminalSymbol([.Unowned])]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class CaptureListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [
                    TerminalSymbol([.Comma]),
                    CaptureListSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class CaptureListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            CaptureSpecifierSymbol(isOptional: true),
            ExpressionSymbol(),
            CaptureListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        var head = CaptureElement(asts[0] as CaptureSpecifier, asts[1] as Expression)
        if let tail = asts[2] as? CaptureElements {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return CaptureElements([head])
    }
}

class CaptureClauseSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftBracket]),
            CaptureListSymbol(),
            TerminalSymbol([.RightBracket],
                           errorGenerator: { [(.ExpectedRightBracket, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class IdentifierListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .Comma {
                return nil
            }
            return [
                TerminalSymbol([.Comma]),
                IdentifierListSymbol()
            ]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class IdentifierListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([identifier],
                           errorGenerator: { [(.ExpectedIdentifier, $0)] }),
            IdentifierListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as Identifier
        if let tail = asts[1] as? Identifiers {
            tail.value.insert(head.value, atIndex: 0)
            return tail
        }
        return Identifiers([head.value])
    }
}

class ClosureTypeClauseSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .LeftParenthesis:
                return [
                    ParameterClauseSymbol(),
                    FunctionResultSymbol(isOptional: true)
                ]
            case .Identifier:
                return [
                    IdentifierListSymbol(),
                    FunctionResultSymbol(isOptional: true)
                ]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        var t = asts[1] as Type
        switch asts[0] {
        case let p as ParameterClause:
            return ClosureTypeClause.Typed(p, t)
        case let i as Identifiers:
            return ClosureTypeClause.Untyped(i.value, t)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

class ClosureSignatureSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .LeftBracket:
                return [
                    CaptureClauseSymbol(),
                    ClosureTypeClauseSymbol(isOptional: true),
                    TerminalSymbol([.In], errorGenerator: { [(.ExpectedIn, $0)] })
                ]
            case .LeftParenthesis, .Identifier:
                return [
                    ClosureTypeClauseSymbol(),
                    TerminalSymbol([.In], errorGenerator: { [(.ExpectedIn, $0)] })
                ]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count > 2 {
            return ClosureSignature(
                (asts[0] as CaptureElements).value,
                asts[1] as? ClosureTypeClause
            )
        }
        return ClosureSignature(nil, (asts[0] as ClosureTypeClause))
    }
}

class ClosureExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftBrace]),
            ClosureSignatureSymbol(isOptional: true),
            StatementsSymbol(),
            TerminalSymbol([.RightBrace])
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let ss = asts[2] as Statements
        if let s = asts[1] as? ClosureSignature {
            return ClosureExpression(s.capture, s.type, ss.value)
        }
        return ClosureExpression(nil, nil, ss.value)
    }
}

class TrailingClosureSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .LeftBrace {
                return nil
            }
            return [ClosureExpressionSymbol()]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class ArrayLiteralItemSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ExpressionSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class ArrayLiteralItemsTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .Comma {
                return nil
            }
            return [
                TerminalSymbol([.Comma]),
                ArrayLiteralItemsSymbol()
            ]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class ArrayLiteralItemsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .RightBracket {
                return nil
            }
            return [
                ArrayLiteralItemSymbol(),
                ArrayLiteralItemsTailSymbol(isOptional: true),
                TerminalSymbol([.Comma], isOptional: true)
            ]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        var head = asts[0] as Expression
        if let tail = asts[1] as? Expressions {
            tail.value.insert(head, atIndex: 0)
        }
        return Expressions([head])
    }
}

class ArrayLiteralSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftBracket]),
            ArrayLiteralItemsSymbol(isOptional: true),
            TerminalSymbol([.RightBracket],
                           errorGenerator: { [(.ExpectedRightBracket, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return LiteralExpression.Array((asts[1] as? Expressions)?.value)
    }
}

class LiteralExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .LeftBracket {
                return [ArrayLiteralSymbol()]
            }
            return [LiteralSymbol()]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class PrimaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Identifier:
                return [TerminalSymbol([identifier])]
            case .IntegerLiteral, .BooleanLiteral, .Nil, .LeftBracket:
                return [LiteralExpressionSymbol()]
            case .LeftBrace:
                return [ClosureExpressionSymbol()]
            case .LeftParenthesis:
                return [ParenthesizedExpressionSymbol()]
            case .Underscore:
                return [WildcardExpressionSymbol()]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let i as Identifier:
            return PrimaryExpression.Reference(i.value)
        case let l as LiteralExpression:
            return PrimaryExpression.Value(l)
        case let c as ClosureExpression:
            return PrimaryExpression.Closure(c)
        case let p as ExpressionElements:
            return PrimaryExpression.Parenthesized(p.value)
        default:
            return asts[0]
        }
    }
}

class SubscriptMemberExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftBracket]),
            ExpressionListSymbol(),
            TerminalSymbol([.RightBracket],
                           errorGenerator: { [(.ExpectedRightBracket, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return PostfixExpression.Subscript((asts[1] as Expressions).value)
    }
}

class ExplicitMemberExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look(1).kind {
            case let .IntegerLiteral(value, decimalDigits: true):
                return [
                    TerminalSymbol([.Dot]),
                    TerminalSymbol([integerLiteral])
                ]
            case .Identifier:
                return [
                    TerminalSymbol([.Dot]),
                    TerminalSymbol([identifier])
                ]
            default:
                // TODO create proper error
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[1] {
        case let n as IntegerLiteral:
            return PostfixExpression.ExplicitMember(
                MemberExpression.Unnamed(n.value)
            )
        case let i as Identifier:
            return PostfixExpression.ExplicitMember(
                MemberExpression.Named(i.value)
            )
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

class FunctionCallExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .LeftParenthesis {
                return [
                    ParenthesizedExpressionSymbol(),
                    TrailingClosureSymbol(isOptional: true)
                ]
            }
            return [TrailingClosureSymbol()]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        var es = asts[0] as ExpressionElements
        return PostfixExpression.FunctionCall(
            es.value,
            asts[1] as? ClosureExpression
        )
    }
}

class PostfixOperatorSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([postfixOperator])
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return PostfixExpression.PostfixOperation((asts[0] as PostfixOperator).value)
    }
}

class PostfixExpressionTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            var rule: [Symbol] = []
            switch tp.look(0, skipLineFeed: false).kind {
            case .PostfixOperator:
                rule.append(PostfixOperatorSymbol())
            case .LeftParenthesis/*, .LeftBrace*/:
                rule.append(FunctionCallExpressionSymbol())
            case .Dot:
                rule.append(ExplicitMemberExpressionSymbol())
            case .LeftBracket:
                rule.append(SubscriptMemberExpressionSymbol())
            default:
                return nil
            }
            rule.append(PostfixExpressionTailSymbol(isOptional: true))
            return rule
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        var head: PostfixExpression = asts[0] as PostfixExpression
        if let tail = asts[1] as? PostfixExpressions {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return PostfixExpressions([head])
    }
}

class PostfixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrimaryExpressionSymbol(),
            PostfixExpressionTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return PrefixExpression(
            nil,
            asts[0] as PrimaryExpression,
            (asts[1] as? PostfixExpressions)?.value
        )
    }
}

class PrefixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([prefixOperator], isOptional: true),
            PostfixExpressionSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        var p = asts[1] as PrefixExpression
        if let o = asts[0] as? PrefixOperator {
            p.op = o.value
        }
        return p
    }
}

class TypeCastingOperatorSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Is:
                return [
                    TerminalSymbol([.Is]),
                    TypeSymbol()
                ]
            case .As:
                if tp.look(1).kind == .BinaryQuestion {
                    return [
                        TerminalSymbol([.As]),
                        TerminalSymbol([.BinaryQuestion]),
                        TypeSymbol()
                    ]
                }
                return [
                    TerminalSymbol([.As]),
                    TypeSymbol()
                ]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] as TypeCastingOperator {
        case .Is:
            return BinaryExpression.IsOperation(asts[1] as Type)
        case .As:
            if asts.count > 2 {
                return BinaryExpression.OptionalAsOperation(asts[2] as Type)
            }
            return BinaryExpression.OptionalAsOperation(asts[1] as Type)
        }
    }
}

class ConditionalOperatorSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.BinaryQuestion]),
            ExpressionSymbol(),
            TerminalSymbol([.Colon], errorGenerator: { [(.ExpectedColon, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class BinaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .BinaryOperator:
                return [
                    TerminalSymbol([binaryOperator]),
                    PrefixExpressionSymbol()
                ]
            case .AssignmentOperator:
                return [
                    TerminalSymbol([.AssignmentOperator]),
                    PrefixExpressionSymbol()
                ]
            case .BinaryQuestion:
                return [
                    ConditionalOperatorSymbol(),
                    PrefixExpressionSymbol()
                ]
            case .Is, .As:
                return [TypeCastingOperatorSymbol()]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let b as BinaryOperator:
            return BinaryExpression.BinaryOperation(
                b.value,
                asts[1] as PrefixExpression
            )
        case let a as AssignmentOperator:
            return BinaryExpression.AssignmentOperation(
                asts[1] as PrefixExpression
            )
        case let e as Expression:
            return BinaryExpression.ConditionalOperation(
                e,
                asts[1] as PrefixExpression
            )
        default:
            return asts[0]
        }
    }
}

class BinaryExpressionsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .BinaryOperator, .AssignmentOperator,
                 .BinaryQuestion, .Is, .As:
                return [
                    BinaryExpressionSymbol(),
                    BinaryExpressionsSymbol(isOptional: true)
                ]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as BinaryExpression
        if let tail = asts[1] as? BinaryExpressions {
            tail.value.insert(head, atIndex: 0)
        }
        return BinaryExpressions([head])
    }
}

class InOutExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.PrefixAmpersand]),
            TerminalSymbol([identifier],
                           errorGenerator: { [(.ExpectedIdentifier, $0)] },
                           skipLineFeed: false)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class ExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in 
            switch tp.look().kind {
            case .PrefixAmpersand:
                return [InOutExpressionSymbol()]
            default:
                return [
                    PrefixExpressionSymbol(),
                    BinaryExpressionsSymbol(isOptional: true)
                ]
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count > 1 {
            return Expression.Term(
                asts[0] as PrefixExpression,
                (asts[1] as? BinaryExpressions)?.value
            )
        }
        return asts[0]
    }
}

class ExpressionListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [
                    TerminalSymbol([.Comma]),
                    ExpressionListSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class ExpressionListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ExpressionSymbol(),
            ExpressionListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as Expression
        if let tail = asts[1] as? Expressions {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return Expressions([head])
    }
}

/*
 * Types
 */
class ArrayTypeSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftBracket]),
            TypeSymbol(),
            TerminalSymbol([.RightBracket],
                           errorGenerator: { [(.ExpectedRightBracket, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Type.Array(ArrayType(asts[1] as Type))
    }
}

class FunctionTypeSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TypeSymbol(),
            TerminalSymbol([.Arrow],
                           errorGenerator: { [(.ExpectedRightBracket, $0)] }),
            TypeSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Type.Function(FunctionType(asts[0] as Type, asts[2] as Type))
    }
}

class ElementNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class TupleTypeElementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            var ahead = tp.look().kind == .Inout ? 1 : 0
            switch tp.look(ahead).kind {
            case .Identifier:
                if tp.look(ahead + 1).kind == .Colon {
                    return [
                        TerminalSymbol([.Inout], isOptional: true),
                        TerminalSymbol(
                            [identifier],
                            errorGenerator: { [(.ExpectedIdentifier, $0)] }
                        ),
                        TypeAnnotationSymbol()
                    ]
                }
            default:
                break
            }
            return [
                TerminalSymbol([.Inout], isOptional: true),
                TypeSymbol()
            ]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        var isInout = (asts[0] as? Inout) != nil
        if asts.count > 2 {
            return TupleTypeElement(
                isInout,
                (asts[1] as Identifier).value,
                asts[2] as Type
            )
        }
        return TupleTypeElement(isInout, nil, asts[1] as Type)
    }
}

class TupleTypeElementListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = true) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [TerminalSymbol([.Comma]), TupleTypeSymbol()]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class TupleTypeElementListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TupleTypeElementSymbol(),
            TupleTypeElementListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as TupleTypeElement
        if let tail = asts[1] as? TupleTypeElements {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return TupleTypeElements([head])
    }
}

class TupleTypeBodySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TupleTypeElementListSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class TupleTypeSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in 
            if tp.look(1).kind == .RightParenthesis {
                return [
                    TerminalSymbol([.LeftParenthesis]),
                    TerminalSymbol(
                        [.RightParenthesis],
                        errorGenerator: { [(.ExpectedRightParenthesis, $0)] }
                    )
                ]
            }
            return [
                TerminalSymbol([.LeftParenthesis]),
                TupleTypeBodySymbol(),
                TerminalSymbol([.RightParenthesis],
                               errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
            ]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count > 2 {
            return Type.Tuple((asts[1] as TupleTypeElements).value)
        }
        return Type.Tuple(nil)
    }
}

class TypeNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class TypeIdentifierSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TypeNameSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return Type.Single((asts[0] as Identifier).value)
    }
}

class TypeAnnotationSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .Colon {
                return nil
            }
            return [TerminalSymbol([.Colon]), TypeSymbol()]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class TypeSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Identifier:
                return [TypeIdentifierSymbol()]
            case .LeftParenthesis:
                return [TupleTypeSymbol()]
            case .LeftBracket:
                return [ArrayTypeSymbol()]
            default:
                return [FunctionTypeSymbol()]
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

/*
 * Patterns
 */
class TuplePatternElementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [PatternSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class TuplePatternElementListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [
                    TerminalSymbol([.Comma]),
                    TuplePatternElementListSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class TuplePatternElementListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TuplePatternElementSymbol(),
            TuplePatternElementListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as Pattern
        if let tail = asts[1] as? TuplePatternElements {
            tail.value!.insert(head, atIndex: 0)
            return tail
        }
        return TuplePatternElements([head])
    }
}

class TuplePatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in 
            if tp.look(1).kind == .RightParenthesis {
                return [
                    TerminalSymbol([.LeftParenthesis]),
                    TerminalSymbol([.RightParenthesis],
                        errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
                ]
            }
            return [
                TerminalSymbol([.LeftParenthesis]),
                TuplePatternElementListSymbol(),
                TerminalSymbol([.RightParenthesis],
                    errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
            ]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count > 2 {
            return asts[1]
        }
        return TuplePatternElements(nil)
    }
}

class ValueBindingPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .Var {
                return [TerminalSymbol([.Var]), PatternSymbol()]
            }
            return [TerminalSymbol([.Let]), PatternSymbol()]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        let p = PatternWrapper(asts[1] as Pattern)
        switch asts[0] as ValueClass {
        case .Var:
            return Pattern.ValueBinding(BindingPattern.Variable(p))
        case .Let:
            return Pattern.ValueBinding(BindingPattern.Constant(p))
        }
    }
}

class IdentifierPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class WildcardPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Underscore])] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class PatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Underscore:
                return [
                    WildcardPatternSymbol(),
                    TypeAnnotationSymbol(isOptional: true)
                ]
            case .Identifier:
                return [
                    IdentifierPatternSymbol(),
                    TypeAnnotationSymbol(isOptional: true)
                ]
            case .Var, .Let:
                return [ValueBindingPatternSymbol()]
            case .LeftParenthesis:
                return [
                    TuplePatternSymbol(),
                    TypeAnnotationSymbol(isOptional: true)
                ]
            default:
                assert(false, "Unexpected syntax error")
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count == 1 {
            return asts[0]
        }
        let t = asts[1] as? Type
        switch asts[0] {
        case _ as Underscore:
            return Pattern.Wildcard(t)
        case let i as Identifier:
            return Pattern.Variable(i.value, t)
        case let tp as TuplePatternElements:
            return Pattern.Tuple(tp.value, t)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

/*
 * Operator declaration
 */
class AssociativitySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Left:
                return [TerminalSymbol([.Left])]
            case .Right:
                return [TerminalSymbol([.Right])]
            case .None:
                return [TerminalSymbol([.None])]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class AssociativityClauseSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Associativity {
                return [TerminalSymbol([.Associativity]), AssociativitySymbol()]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class PrecedenceLevelSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case let .IntegerLiteral(value, decimalDigits: true):
                if(0 <= value && value <= 255) {
                    return [TerminalSymbol([integerLiteral])]
                }
                // TODO create proper error
                fallthrough
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class PrecedenceClauseSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Precedence {
                return [TerminalSymbol([.Precedence]), PrecedenceLevelSymbol()]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class InfixOperatorAttributesSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            // TODO list all not infix operator attribute heading
            case .RightBrace:
                return nil
            default:
                return [
                    PrecedenceClauseSymbol(isOptional: true),
                    AssociativityClauseSymbol(isOptional: true)
                ]
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return InfixOperatorAttributes(
            (asts[0] as? IntegerLiteral)?.value,
            asts[1] as? Associativity
        )
    }
}

class PrefixOperatorDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Prefix]),
            TerminalSymbol([.Operator],
                           errorGenerator: { [(.ExpectedOperator, $0)] }),
            TerminalSymbol([binaryOperator],
                           errorGenerator: { [(.ExpectedPrefixOperator, $0)] }),
            TerminalSymbol([.LeftBrace],
                           errorGenerator: { [(.ExpectedLeftBrace, $0)] }),
            TerminalSymbol([.RightBrace], 
                           errorGenerator: { [(.ExpectedRightBrace, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Declaration.PrefixOperator((asts[2] as BinaryOperator).value)
    }
}

class PostfixOperatorDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Postfix]),
            TerminalSymbol([.Operator],
                           errorGenerator: { [(.ExpectedOperator, $0)] }),
            TerminalSymbol([binaryOperator],
                           errorGenerator: { [(.ExpectedPostfixOperator, $0)] }),
            TerminalSymbol([.LeftBrace],
                           errorGenerator: { [(.ExpectedLeftBrace, $0)] }),
            TerminalSymbol([.RightBrace],
                           errorGenerator: { [(.ExpectedRightBrace, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Declaration.PostfixOperator((asts[2] as BinaryOperator).value)
    }
}

class InfixOperatorDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Infix]),
            TerminalSymbol([.Operator], errorGenerator: { [(.ExpectedOperator, $0)] }),
            TerminalSymbol([binaryOperator],
                           errorGenerator: { [(.ExpectedBinaryOperator, $0)] }),
            TerminalSymbol([.LeftBrace],
                           errorGenerator: { [(.ExpectedLeftBrace, $0)] }),
            InfixOperatorAttributesSymbol(isOptional: true),
            TerminalSymbol([.RightBrace],
                           errorGenerator: { [(.ExpectedRightBrace, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let a = asts[4] as? InfixOperatorAttributes
        return Declaration.InfixOperator(
            (asts[2] as BinaryOperator).value,
            a?.precedence,
            a?.associativity
        )
    }
}

class OperatorDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Prefix:
                return [PrefixOperatorDeclarationSymbol()]
            case .Postfix:
                return [PostfixOperatorDeclarationSymbol()]
            case .Infix:
                return [InfixOperatorDeclarationSymbol()]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

/*
 * Function declaration
 */
class DefaultArgumentClauseSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .AssignmentOperator {
                return [
                    TerminalSymbol([.AssignmentOperator]),
                    ExpressionSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class LocalParameterNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .Underscore {
                return [TerminalSymbol(
                    [.Underscore],
                    errorGenerator: { [(.ExpectedUnderscore, $0)] }
                )]
            }
            return [TerminalSymbol(
                [identifier],
                errorGenerator: { [(.ExpectedIdentifier, $0)] }
            )]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if let i = asts[0] as? Identifier {
            return ParameterName(i.value)
        }
        return ParameterName(nil)
    }
}

class ExternalParameterNameSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .Identifier:
                if tp.look(1).kind == .Colon {
                    return nil
                }
                return [TerminalSymbol(
                    [identifier],
                    errorGenerator: { [(.ExpectedIdentifier, $0)] }
                )]
            case .Underscore:
                if tp.look(1).kind == .Colon {
                    return nil
                }
                return [TerminalSymbol(
                    [.Underscore],
                    errorGenerator: { [(.ExpectedUnderscore, $0)] }
                )]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        if let i = asts[0] as? Identifier {
            return ParameterName(i.value)
        }
        return ParameterName(nil)
    }
}

class ParameterSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Inout], isOptional: true),
            TerminalSymbol([.Let, .Var], isOptional: true),
            TerminalSymbol([.Hash], isOptional: true),
            ExternalParameterNameSymbol(isOptional: true),
            LocalParameterNameSymbol(),
            TypeAnnotationSymbol(),
            DefaultArgumentClauseSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        var p = Parameter(
            false,
            false,
            (asts[3] as? ParameterName)?.value,
            (asts[4] as ParameterName).value,
            asts[5] as Type,
            asts[6] as? Expression
        )
        if let io = asts[0] as? Inout {
            p.isInout = true
        }
        if let v = asts[1] as? ValueClass {
            switch v {
            case .Let:
                p.isConstant = true
            case .Var:
                break
            }
        }
        if let h = asts[2] as? Hash {
            if p.externalName == nil {
                p.externalName = p.localName
            }
        }
        return p
    }
}

class ParameterListTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [
                    TerminalSymbol([.Comma]),
                    ParameterListSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class ParameterListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ParameterSymbol(),
            ParameterListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as Parameter
        if let tail = asts[1] as? Parameters {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return Parameters([head])
    }
}

class ParameterClauseSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look(1).kind == .RightParenthesis {
                return [
                    TerminalSymbol([.LeftParenthesis]),
                    TerminalSymbol(
                        [.RightParenthesis],
                        errorGenerator: { [(.ExpectedRightParenthesis, $0)] }
                    )
                ]
            }
            return [
                TerminalSymbol([.LeftParenthesis]),
                ParameterListSymbol(),
                TerminalSymbol(
                    [.RightParenthesis],
                    errorGenerator: { [(.ExpectedRightParenthesis, $0)] }
                )
            ]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return ParameterClause((asts[1] as? Parameters)?.value)
    }
}

class ParameterClausesSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .LeftParenthesis {
                return [
                    ParameterClauseSymbol(),
                    ParameterClausesSymbol(isOptional: true)
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as ParameterClause
        if let tail = asts[1] as? ParameterClauses {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return ParameterClauses([head])
    }
}

class FunctionBodySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [CodeBlockSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class FunctionResultSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Arrow {
                return [
                    TerminalSymbol([.Arrow]),
                    TypeSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class FunctionSignatureSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ParameterClausesSymbol(),
            FunctionResultSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return FunctionSignature(
            (asts[0] as ParameterClauses).value,
            asts[1] as? Type
        )
    }
}

class FunctionNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == identifier {
                return [TerminalSymbol([identifier])]
            }
            return [TerminalSymbol([prefixOperator, postfixOperator, binaryOperator])]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let i as Identifier:
            return FunctionName.Function(i.value)
        case let pr as PrefixOperator:
            return FunctionName.Operator(pr.value)
        case let po as PostfixOperator:
            return FunctionName.Operator(po.value)
        case let b as BinaryOperator:
            return FunctionName.Operator(b.value)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

class FunctionHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Func])]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class FunctionDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            FunctionHeadSymbol(),
            FunctionNameSymbol(),
            FunctionSignatureSymbol(),
            FunctionBodySymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let fs = asts[2] as FunctionSignature
        let b = asts[3] as Statements
        switch asts[1] as FunctionName {
        case let .Function(k):
            return Declaration.Function(k, fs.parameter, fs.result, b.value)
        case let .Operator(s):
            return Declaration.OperatorFunction(s, fs.parameter, fs.result, b.value)
        }
    }
}

/*
 * Typealias declaration
 */
class TypealiasAssignmentSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.AssignmentOperator],
                           errorGenerator: { [(.ExpectedAssignmentOperator, $0)] }),
            TypeSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class TypealiasNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([identifier],
                           errorGenerator: { [(.ExpectedAssignmentOperator, $0)] }),
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class TypealiasHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Typealias]), TypealiasNameSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class TypealiasDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TypealiasHeadSymbol(),
            TypealiasAssignmentSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Declaration.Typealias(
            (asts[0] as Identifier).value,
            asts[1] as Type
        )
    }
}

/*
 * Constant declaration, Variable declaration
 */
class InitializerSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .AssignmentOperator {
                return [
                    TerminalSymbol([.AssignmentOperator]),
                    ExpressionSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class PatternInitializerSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PatternSymbol(),
            InitializerSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return PatternInitializer(
            asts[0] as Pattern,
            asts[1] as? Expression
        )
    }
}

class PatternInitializerTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [
                    TerminalSymbol([.Comma]),
                    PatternInitializerListSymbol(),
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class PatternInitializerListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PatternInitializerSymbol(),
            PatternInitializerTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        let head = asts[0] as PatternInitializer
        if let tail = asts[1] as? PatternInitializers {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return PatternInitializers([head])
    }
}

class VariableDeclarationHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Var])] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class VariableDeclarationSymbol: NonTerminalSymbol {
    init() {
        super.init({ tp in [
            VariableDeclarationHeadSymbol(),
            PatternInitializerListSymbol(),
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Declaration.Variable((asts[1] as PatternInitializers).value)
    }
}

class ConstantDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Let]),
            PatternInitializerListSymbol(),
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Declaration.Constant((asts[1] as PatternInitializers).value)
    }
}

/*
 * Decralations
 */
class CodeBlockSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.LeftBrace],
                           errorGenerator: { [(.ExpectedLeftBrace, $0)] }),
            StatementsSymbol(isOptional: true),
            TerminalSymbol([.RightBrace],
                           errorGenerator: { [(.ExpectedRightBrace, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[1]
    }
}

class DeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Let:
                return [ConstantDeclarationSymbol()]
            case .Var:
                return [VariableDeclarationSymbol()]
            case .Typealias:
                return [TypealiasDeclarationSymbol()]
            case .Func:
                return [FunctionDeclarationSymbol()]
            case .Prefix, .Infix, .Postfix:
                return [OperatorDeclarationSymbol()]
            default:
                // TODO create proper error
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

/*
 * Loop statement
 */
class ForInitSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .Semicolon:
                return nil
            case .Var:
                return [VariableDeclarationSymbol()]
            default:
                return [ExpressionListSymbol()]
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let i as Declaration:
            return ForInit.VariableDeclaration(i)
        case let i as Expressions:
            return ForInit.Terms(i.value)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

class ForConfirmationSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Semicolon {
                return nil
            }
            return [ExpressionSymbol()]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class ForFinalize: NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .LeftBrace {
                return nil
            }
            return [ExpressionSymbol()]
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class ForConditionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ForInitSymbol(isOptional: true),
            TerminalSymbol(
                [.Semicolon],
                errorGenerator: { [(.ExpectedSemicolon, $0)] }
            ),
            ForConfirmationSymbol(isOptional: true),
            TerminalSymbol(
                [.Semicolon],
                errorGenerator: { [(.ExpectedSemicolon, $0)] }
            ),
            ForFinalize(isOptional: true),
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return ForCondition(
            asts[0] as? ForInit,
            asts[2] as? Expression,
            asts[4] as? Expression
        )
    }
}

class ForInStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.For]),
            PatternSymbol(),
            TerminalSymbol([.In], errorGenerator: { [(.ExpectedIn, $0)] }),
            ExpressionSymbol(),
            CodeBlockSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Statement.ForIn(
            asts[1] as Pattern,
            asts[3] as Expression,
            (asts[4] as? Statements)?.value,
            nil
        )
    }
}

class ForStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look(1).kind == .LeftParenthesis {
                return [
                    TerminalSymbol([.For]),
                    TerminalSymbol([.LeftParenthesis]),
                    ForConditionSymbol(),
                    TerminalSymbol([.RightParenthesis],
                                   errorGenerator: { [(.ExpectedRightParenthesis, $0)] }),
                    CodeBlockSymbol()
                ]
            }
            return [
                TerminalSymbol([.For]),
                ForConditionSymbol(),
                CodeBlockSymbol()
            ]
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        var condition = 1
        var body = 2
        if asts.count > 3 {
            condition = 2
            body = 4
        }
        return Statement.For(
            asts[condition] as ForCondition,
            (asts[body] as? Statements)?.value,
            nil
        )
    }
}

class WhileConditionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Let, .Var, .Typealias,  .Func, .Prefix, .Infix, .Postfix:
                return [DeclarationSymbol()]
            default:
                return [ExpressionSymbol()]
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let c as Expression:
            return WhileCondition.Term(c)
        case let c as Declaration:
            return WhileCondition.Definition(c)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

class DoWhileStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Do]),
            CodeBlockSymbol(),
            TerminalSymbol([.While], errorGenerator: { [(.ExpectedWhile, $0)] }),
            WhileConditionSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Statement.DoWhile(
            asts[3] as WhileCondition,
            (asts[1] as? Statements)?.value,
            nil
        );
    }
}

class WhileStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.While]),
            WhileConditionSymbol(),
            CodeBlockSymbol()
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return Statement.While(
            asts[1] as WhileCondition,
            (asts[2] as? Statements)?.value,
            nil
        )
    }
}

class LoopStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .For:
                return findDFA(tp, [(
                    .Semicolon,
                    { [ForStatementSymbol()] }
                ), (
                    .In,
                    { [ForInStatementSymbol()] }
                )], startIndex: 1)
            case .While:
                return [WhileStatementSymbol()]
            case .Do:
                return [DoWhileStatementSymbol()]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

/*
 * Branch statement
 */
class ElseClauseSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Else {
                if tp.look(1).kind == .If {
                    return [TerminalSymbol([.Else]), CodeBlockSymbol()]
                } else if tp.look(1).kind == .LeftBrace {
                    return [TerminalSymbol([.Else]), IfStatementSymbol()]
                }
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        if let e = asts[1] as? Statement {
            return ElseClause.ElseIf(StatementWrapper(e))
        }
        return ElseClause.Else((asts[1] as? Statements)?.value)
    }
}

class IfConditionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ExpressionSymbol()] })
    }

    override func generateAST(asts: [AST]) -> AST {
        return IfCondition.Term(asts[0] as Expression)
    }
}

class IfStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.If]),
            IfConditionSymbol(),
            CodeBlockSymbol(),
            ElseClauseSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        var cond = asts[1] as IfCondition
        var body = (asts[2] as? Statements)?.value
        if let e = asts[3] as? OptionalParts {
            return Statement.If(cond, body, nil)
        }
        return Statement.If(cond, body, asts[3] as? ElseClause)
    }
}

class BranchStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ IfStatementSymbol() ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

/*
 * Labeled statement
 */
class LabelNameSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case let .Identifier(k):
                switch k {
                case .Identifier:
                    fallthrough
                case .QuotedIdentifier:
                    return [TerminalSymbol([identifier])]
                case .ImplicitParameter:
                    // TODO create proper error
                    return nil
                }
            default:
                return nil
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class StatementLabelSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            LabelNameSymbol(),
            TerminalSymbol([.Colon], errorGenerator: { [(.ExpectedColon, $0)] })
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

class LabeledStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementLabelSymbol(), LoopStatementSymbol()] });
    }

    override func generateAST(asts: [AST]) -> AST {
        var l = asts[0] as Identifier
        switch asts[1] as Statement {
        case let .For(c, b, _):
            return Statement.For(c, b, l.value)
        case let .ForIn(p, e, s, _):
            return Statement.ForIn(p, e, s, l.value)
        case let .While(c, b, _):
            return Statement.While(c, b, l.value)
        case let .DoWhile(c, b, _):
            return Statement.DoWhile(c, b, l.value)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

/*
 * Control transfer statement
 */
class BreakStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Break]),
            LabelNameSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        if let l = asts[1] as? OptionalParts {
            return Statement.Break(nil)
        }
        return Statement.Break((asts[1] as? Identifier)?.value)
    }
}

class ContinueStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Continue]),
            LabelNameSymbol(isOptional: true)
        ]})
    }

    override func generateAST(asts: [AST]) -> AST {
        if let l = asts[1] as? OptionalParts {
            return Statement.Continue(nil)
        }
        return Statement.Continue((asts[1] as? Identifier)?.value)
    }
}

class ReturnStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look(1).kind {
            case .LineFeed, .Semicolon, .EndOfFile:
                return [TerminalSymbol([.Return])]
            default:
                return [
                    TerminalSymbol([.Return]),
                    ExpressionSymbol()
                ]
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        if asts.count < 2 {
            return Statement.Return(nil)
        }
        return Statement.Return(asts[1] as? Expression)
    }
}

class ControlTransferStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Break:
                return [BreakStatementSymbol()]
            case .Continue:
                return [ContinueStatementSymbol()]
            case .Return:
                return [ReturnStatementSymbol()]
            default:
                return nil
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        return asts[0]
    }
}

/*
 * Statements
 */
class StatementSymbol : NonTerminalSymbol {
    init() {
        let term = TerminalSymbol([.LineFeed, .Semicolon, .EndOfFile],
                                  errorGenerator: { [(.ExpectedEndOfStatement, $0)] })
        super.init({ tp in
            switch tp.look().kind {
            case .Let, .Var, .Typealias, .Func, .Prefix, .Infix, .Postfix:
                return [DeclarationSymbol(), term]
            case .For, .While, .Do:
                return [LoopStatementSymbol(), term]
            case .If:
                return [BranchStatementSymbol(), term]
            case .Identifier:
                if tp.look(1).kind == .Colon {
                    return [LabeledStatementSymbol(), term]
                }
                return [ExpressionSymbol(), term]
            case .Break, .Continue, .Return:
                return [ControlTransferStatementSymbol(), term]
            default:
                return [ExpressionSymbol(), term]
            }
        })
    }

    override func generateAST(asts: [AST]) -> AST {
        switch asts[0] {
        case let s as Expression:
            return Statement.Term(s)
        case let s as Declaration:
            return Statement.Definition(s)
        default:
            return asts[0]
        }
    }
}

class StatementsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in 
            switch tp.look().kind {
            case .EndOfFile, .Semicolon, .Colon,
                 .Comma, .Arrow, .Hash, .Dot,
                 .AssignmentOperator,
                 .RightParenthesis, .RightBrace, .RightBracket,
                 .PostfixGraterThan, .BinaryQuestion, .PostfixQuestion,
                 .PostfixExclamation, .PostfixOperator, .As, .Is:
                return nil
            default:
                return [StatementSymbol(), StatementsSymbol(isOptional: true)]
            }
        }, isOptional: isOptional)
    }

    override func generateAST(asts: [AST]) -> AST {
        var head = asts[0] as Statement
        if let tail = asts[1] as? Statements {
            tail.value.insert(head, atIndex: 0)
            return tail
        }
        return Statements([head])
    }
}

/*
 * Top level declaration
 */
class TopLevelDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementsSymbol(isOptional: true)] })
    }

    override func generateAST(asts: [AST]) -> AST {
        var ss = asts[0] as? Statements
        return TopLevelDeclaration(ss?.value)
    }
}

public class Parser {
    private let ts: TokenStream!

    public init?(_ file: File) {
        ts = TokenStream(file)
        if ts == nil {
            return nil
        }
    }

    public func parse() -> ParseResult {
        var errors: [Error] = []
        var asts: [AST] = []
        let stack: [Symbol] = [
            TopLevelDeclarationSymbol(),
            TerminalSymbol([.EndOfFile],
                           errorGenerator: { [(.ExpectedEndOfFile, $0)] })
        ]
        for element in stack {
            switch element.parse(ts) {
            case let .Success(ast):
                asts.append(ast);
            case let .Failure(es):
                errors.extend(es)
            }
        }
        if errors.count > 0 {
            return .Failure(errors)
        } else {
            return .Success(asts[0])
        }
    }
}
