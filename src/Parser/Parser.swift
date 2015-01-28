import Util

public enum ParseResult {
    case Success(ASTParts)
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
                    /* */
                    if let s = inputToken.info.source {
                        println("\(s)")
                    }
                    /* */
                    return .Success(Terminal(inputToken))
                } else if self.skipLineFeed {
                    inputToken = input.look(1)
                    if kind == inputToken.kind {
                        input.next(n: 2)
                        /* */
                        if let s = inputToken.info.source {
                            println("\(s)")
                        }
                        /* */
                        return .Success(Terminal(inputToken))
                    }
                }
            }
        default:
            for kind in kinds {
                if inputToken.kind == kind {
                    input.next()
                    if let s = inputToken.info.source {
                        println("\(s)")
                    }
                    return .Success(Terminal(inputToken))
                }
            }
        }
        if isOptional {
            println("\t(optional)")
            return .Success(OptionalParts())
        }

        if let eg = errorGenerator {
            return .Failure(eg(inputToken.info))
        }
        assert(false, "Unexpected syntax error")
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
        println("\(reflect(self).summary)")
        switch input.look().kind {
        case let .Error(e):
            return .Failure([(e, input.look().info)])
        default:
            break
        }
        var errors: [Error] = []
        var asts: [ASTParts] = []
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
                return .Success(generateAST(elements, asts))
            }
        } else if isOptional {
            println("\t(optional)")
            return .Success(OptionalParts())
        }
        return .Failure([(.UnexpectedSymbol, input.look().info)])
    }

    func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unimplemented ASTParts generation")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        return asts[0]
    }
}

/*
 * Expressions
 */
class WildcardExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Underscore])] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class CaptureListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            CaptureSpecifierSymbol(isOptional: true),
            ExpressionSymbol()
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class ArrayLiteralItemSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ExpressionSymbol()] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PostfixExpressionTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            var rule: [Symbol] = []
            switch tp.look(0, skipLineFeed: false).kind {
            case .PostfixOperator:
                rule.append(TerminalSymbol(
                    [postfixOperator],
                    errorGenerator: { [(.ExpectedPostfixOperator, $0)] }
                ))
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PostfixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrimaryExpressionSymbol(),
            PostfixExpressionTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PrefixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([prefixOperator], isOptional: true),
            PostfixExpressionSymbol()
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class ExpressionListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ExpressionSymbol(),
            ExpressionListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class ElementNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TupleTypeElementListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TupleTypeElementSymbol(),
            TupleTypeElementListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TupleTypeBodySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TupleTypeElementListSymbol()] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TypeNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TypeIdentifierSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TypeNameSymbol()] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

/*
 * Patterns
 */
class TuplePatternElementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [PatternSymbol()] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TuplePatternElementListSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .RightParenthesis {
                return [
                    TuplePatternElementSymbol(),
                    TuplePatternElementListTailSymbol(isOptional: true)
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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
                TuplePatternElementListSymbol(isOptional: true),
                TerminalSymbol([.RightParenthesis],
                    errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
            ]
        })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class IdentifierPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class WildcardPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Underscore])] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PrefixOperatorDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Prefix]),
            TerminalSymbol([.Operator],
                           errorGenerator: { [(.ExpectedOperator, $0)] }),
            TerminalSymbol([prefixOperator],
                           errorGenerator: { [(.ExpectedPrefixOperator, $0)] }),
            TerminalSymbol([.LeftBrace],
                           errorGenerator: { [(.ExpectedLeftBrace, $0)] }),
            TerminalSymbol([.RightBrace], 
                           errorGenerator: { [(.ExpectedRightBrace, $0)] })
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PostfixOperatorDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Postfix]),
            TerminalSymbol([.Operator],
                           errorGenerator: { [(.ExpectedOperator, $0)] }),
            TerminalSymbol([postfixOperator],
                           errorGenerator: { [(.ExpectedPostfixOperator, $0)] }),
            TerminalSymbol([.LeftBrace],
                           errorGenerator: { [(.ExpectedLeftBrace, $0)] }),
            TerminalSymbol([.RightBrace],
                           errorGenerator: { [(.ExpectedRightBrace, $0)] })
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class ParameterListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ParameterSymbol(),
            ParameterListTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class FunctionBodySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [CodeBlockSymbol()] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class FunctionSignatureSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ParameterClausesSymbol(),
            FunctionResultSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class FunctionHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Func])]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TypealiasNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([identifier],
                           errorGenerator: { [(.ExpectedAssignmentOperator, $0)] }),
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TypealiasHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Typealias]), TypealiasNameSymbol()] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class TypealiasDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TypealiasHeadSymbol(),
            TypealiasAssignmentSymbol()
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PatternInitializerSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PatternSymbol(),
            InitializerSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class PatternInitializerTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Comma {
                return [
                    TerminalSymbol([.Comma]),
                    PatternInitializerSymbol(),
                    PatternInitializerTailSymbol(isOptional: true)
                ]
            }
            return nil
        }, isOptional: isOptional)
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class VariableDeclarationHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Var])] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class VariableDeclarationSymbol: NonTerminalSymbol {
    init() {
        super.init({ tp in [
            VariableDeclarationHeadSymbol(),
            PatternInitializerSymbol(),
            PatternInitializerTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
    }
}

class ConstantDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Let]),
            PatternInitializerSymbol(),
            PatternInitializerTailSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        assert(false, "Unexpected syntax error")
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        let token = (asts[0] as Terminal).value
        switch token.kind {
        case let .Identifier(k):
            return Identifier(k)
        default:
            assert(false, "Unexpected syntax error")
        }
    }
}

class StatementLabelSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            LabelNameSymbol(),
            TerminalSymbol([.Colon], errorGenerator: { [(.ExpectedColon, $0)] })
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        return asts[0]
    }
}

class LabeledStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementLabelSymbol(), LoopStatementSymbol()] });
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        var l = asts[0] as Identifier
        switch asts[1] as Statement {
        case let .For(c, b, _):
            return Statement.For(c, b, l)
        case let .ForIn(p, e, s, _):
            return Statement.ForIn(p, e, s, l)
        case let .While(c, b, _):
            return Statement.While(c, b, l)
        case let .DoWhile(c, b, _):
            return Statement.DoWhile(c, b, l)
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        if let l = asts[1] as? OptionalParts {
            return Statement.Break(nil)
        }
        return Statement.Break(asts[1] as? Identifier)
    }
}

class ContinueStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Continue]),
            LabelNameSymbol(isOptional: true)
        ]})
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        if let l = asts[1] as? OptionalParts {
            return Statement.Continue(nil)
        }
        return Statement.Continue(asts[1] as? Identifier)
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
        var s = asts[0] as Statement
        if let ss = asts[1] as? OptionalParts {
            return Statements([s])
        }
        var ss: [Statement] = (asts[1] as Statements).value
        ss.insert(s, atIndex: 0)
        return Statements(ss)
    }
}

/*
 * Top level declaration
 */
class TopLevelDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementsSymbol(isOptional: true)] })
    }

    override func generateAST(rule: [Symbol], _ asts: [ASTParts]) -> ASTParts {
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
        var asts: [ASTParts] = []
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
