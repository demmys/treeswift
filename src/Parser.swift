typealias Error = (ErrorMessage, SourceInfo)

enum ParseResult {
    case Success
    case Failure([Error])
}

private let identifier = TokenKind.Identifier(.Identifier(""))
private let integerLiteral = TokenKind.IntegerLiteral(0, decimalDigit: false)
private let prefixOperator = TokenKind.PrefixOperator("")
private let postfixOperator = TokenKind.PostfixOperator("")
private let binaryOperator = TokenKind.BinaryOperator("")

private func equalDFA(tp: TokenPeeper,
                      target: TokenKind,
                      index: Int = 0,
                      skipLineFeed: Bool = true) -> Bool {
    switch tp.look(index).kind {
    case target:
        return true
    case .LineFeed:
        if skipLineFeed && tp.look(index + 1).kind == target {
            return true
        }
    default:
        return false
    }
    return false
}

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

private func countDFA(tp: TokenPeeper,
                      target: TokenKind,
                      startIndex: Int = 0) -> Int? {
    var i = startIndex
    var kind = tp.look(i).kind
    while kind != .EndOfFile {
        if kind == target {
            return i
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

    init(_ kinds: [TokenKind], errorGenerator: (SourceInfo -> [Error])? = nil,
         isOptional: Bool = false) {
        self.kinds = kinds
        self.errorGenerator = errorGenerator
        self.isOptional = isOptional
    }

    func parse(input: TokenStream) -> ParseResult {
        var inputToken = input.look()
        switch inputToken.kind {
        case let .Error(e):
            return .Failure([(e, inputToken.info)])
        case .LineFeed:
            for kind in kinds {
                if kind == .LineFeed {
                    input.next()
                    return .Success
                } else if kind == input.look(1).kind {
                    input.next(n: 1)
                    return .Success
                }
            }
        default:
            for kind in kinds {
                if inputToken.kind == kind {
                    input.next()
                    return .Success
                }
            }
        }
        if isOptional {
            return .Success
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
     * returns nil when there's no rule to apply to
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
        if let elements = ruleArbiter(input) {
            for element in elements {
                switch element.parse(input) {
                case .Success:
                    break
                case let .Failure(es):
                    errors.extend(es)
                }
            }
            if errors.count > 0 {
                return .Failure(errors)
            } else {
                return .Success
            }
        } else if isOptional {
            return .Success
        }
        return .Failure([(.UnexpectedSymbol, input.look().info)])
    }
}

/*
 * Literals
 */
class LiteralSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.IntegerLiteral(0, decimalDigit: false)], errorGenerator: {
                [(.ExpectedIntegerLiteral, $0)]
            })
        ]})
    }
}

/*
 * Expressions
 */
class LiteralExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [LiteralSymbol()] })
    }
}

class PrimaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind != .LeftParenthesis {
                return [LiteralExpressionSymbol()]
            }
            return [
                TerminalSymbol([.LeftParenthesis], errorGenerator: {
                    [(.ExpectedLeftParenthesis, $0)]
                }),
                ExpressionSymbol(),
                TerminalSymbol([.RightParenthesis], errorGenerator: {
                    [(.ExpectedRightParenthesis, $0)]
                })
            ]
        })
    }
}


class PostfixExpressionTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .PostfixOperator("") {
                return nil
            }
            return [
                TerminalSymbol([.PostfixOperator("")], errorGenerator: {
                    [(.ExpectedPostfixOperator, $0)]
                }),
                PostfixExpressionTailSymbol(isOptional: true)
            ]
        }, isOptional: isOptional)
    }
}

class PostfixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrimaryExpressionSymbol(),
            PostfixExpressionTailSymbol(isOptional: true)
        ]})
    }
}

class PrefixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.PrefixOperator("")], errorGenerator: {
                [(.ExpectedPrefixOperator, $0)]
            }, isOptional: true),
            PostfixExpressionSymbol()
        ]})
    }
}

class BinaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.BinaryOperator("")], errorGenerator: {
                [(.ExpectedBinaryOperator, $0)]
            }),
            PrefixExpressionSymbol()
        ]})
    }
}

class BinaryExpressionsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind != .BinaryOperator("") {
                return nil
            }
            return [
                BinaryExpressionSymbol(),
                BinaryExpressionsSymbol(isOptional: true)
            ]
        }, isOptional: isOptional)
    }
}

class ExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrefixExpressionSymbol(),
            BinaryExpressionsSymbol(isOptional: true)
        ]})
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
}

class ExpressionListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ExpressionSymbol(), ExpressionListTailSymbol(isOptional: true)] })
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
}

class ElementNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }
}

class TupleTypeElementTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == identifier {
                return [
                    ElementNameSymbol(),
                    TypeAnnotationSymbol()
                ]
            }
            return nil
        }, isOptional: isOptional)
    }
}

class TupleTypeElementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .Inout {
                return [
                    TerminalSymbol([.Inout]),
                    TypeSymbol(),
                    TupleTypeElementTailSymbol(isOptional: true)
                ]
            }
            return nil
        })
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
}

class TupleTypeElementListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TupleTypeElementSymbol(),
            TupleTypeElementTailSymbol(isOptional: true)
        ]})
    }
}

class TupleTypeBodySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TupleTypeElementListSymbol()] })
    }
}

class TupleTypeSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in 
            if equalDFA(tp, .RightParenthesis, index: 1) {
                return [
                    TerminalSymbol([.LeftParenthesis]),
                    TerminalSymbol([.RightParenthesis],
                        errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
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
}

class TypeNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }
}

class TypeIdentifierSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TypeNameSymbol()] })
    }
}

class TypeAnnotationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Colon]), TypeSymbol()] })
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
}

/*
 * Patterns
 */
class ExpressionPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ExpressionSymbol()] })
    }
}

class IsPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Is]),
            TypeSymbol()
        ]})
    }
}

class TypeCastingPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [IsPatternSymbol()] })
    }
}

class TuplePatternElementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [PatternSymbol()] })
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
}

class TuplePatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in 
            if equalDFA(tp, .RightParenthesis, index: 1) {
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
}

class IdentifierPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([identifier])] })
    }
}

class WildcardPatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Underscore])] })
    }
}

class PatternSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Underscore:
                return [WildcardPatternSymbol()]
            case .Identifier:
                return [IdentifierPatternSymbol()]
            case .Var, .Let:
                return [ValueBindingPatternSymbol()]
            case .LeftParenthesis:
                return [TuplePatternSymbol()]
            case .Is:
                return [TypeCastingPatternSymbol()]
            default:
                return [ExpressionPatternSymbol()]
            }
        })
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
                assert(false, "Unexpected syntax error")
            }
        })
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
}

class LocalParameterNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .Underscore {
                return [TerminalSymbol([.Underscore])]
            }
            return [TerminalSymbol([identifier])]
        })
    }
}

class ExternalParameterNameSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind {
            case .Identifier:
                return [TerminalSymbol([identifier])]
            case .Underscore:
                return [TerminalSymbol([.Underscore])]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }
}

class ParameterSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            var rule: [Symbol] = []
            var i = 0
            if tp.look().kind == .Inout {
                rule.append(TerminalSymbol([.Inout]))
                ++i
            }
            switch tp.look(i).kind {
            case .Let:
                rule.append(TerminalSymbol([.Let]))
                ++i
            case .Var:
                rule.append(TerminalSymbol([.Var]))
                ++i
            default:
                break
            }
            if tp.look(i).kind == .Hash {
                rule.append(TerminalSymbol([.Hash]))
                ++i
            }
            switch tp.look(i + 1).kind {
            case .Identifier, .Underscore:
                rule.append(ExternalParameterNameSymbol(isOptional: true))
                fallthrough
            default:
                rule.append(LocalParameterNameSymbol())
            }
            rule.append(TypeAnnotationSymbol())
            rule.append(DefaultArgumentClauseSymbol(isOptional: true))
            return rule
        })
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
}

class ParameterListSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ParameterSymbol(),
            ParameterListTailSymbol(isOptional: true)
        ]})
    }
}

class ParameterClauseSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if equalDFA(tp, .RightParenthesis, index: 1) {
                return [
                    TerminalSymbol([.LeftParenthesis]),
                    TerminalSymbol([.RightParenthesis],
                        errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
                ]
            }
            return [
                TerminalSymbol([.LeftParenthesis]),
                ParameterListSymbol(),
                TerminalSymbol([.RightParenthesis],
                    errorGenerator: { [(.ExpectedRightParenthesis, $0)] })
            ]
        })
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
}

class FunctionBodySymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [CodeBlockSymbol()] })
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
}

class FunctionSignatureSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ParameterClausesSymbol(),
            FunctionResultSymbol(isOptional: true)
        ]})
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
}

class FunctionHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Func])]})
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
}

class TypealiasNameSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([identifier],
                           errorGenerator: { [(.ExpectedAssignmentOperator, $0)] }),
        ]})
    }
}

class TypealiasHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Typealias]), TypealiasNameSymbol()] })
    }
}

class TypealiasDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TypealiasHeadSymbol(),
            TypealiasAssignmentSymbol()
        ]})
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
}

class PatternInitializerSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PatternSymbol(),
            InitializerSymbol(isOptional: true)
        ]})
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
}

class VariableDeclarationHeadSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol([.Var])] })
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
}

class ConstantDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Let]),
            PatternInitializerSymbol(),
            PatternInitializerTailSymbol(isOptional: true)
        ]})
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
}

/*
 * Loop statement
 */
class ForInitSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind {
            case .Var:
                return [VariableDeclarationSymbol()]
            default:
                return [ExpressionListSymbol()]
            }
        })
    }
}

class ForConditionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            var i = 0
            var rule: [Symbol] = []
            // optional for-init
            if equalDFA(tp, .Semicolon) {
                i = 1
            } else {
                rule.append(ForInitSymbol())
                if let j = countDFA(tp, .Semicolon) {
                    i = j
                } else {
                    return nil
                }
            }
            // Semicolon
            rule.append(TerminalSymbol(
                [.Semicolon],
                errorGenerator: { [(.ExpectedSemicolon, $0)] }
            ))
            // optional discriminate expression
            if equalDFA(tp, .Semicolon, index: i) {
                ++i
            } else {
                rule.append(ExpressionSymbol())
                if let j = countDFA(tp, .Semicolon, startIndex: i) {
                    i = j
                } else {
                    return nil
                }
            }
            // Semicolon
            rule.append(TerminalSymbol(
                [.Semicolon],
                errorGenerator: { [(.ExpectedSemicolon, $0)] }
            ))
            // optional post loop expression
            if !equalDFA(tp, .LeftBrace, index: i) {
                rule.append(ExpressionSymbol())
            }
            return rule
        })
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
}

class ForStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if equalDFA(tp, .LeftParenthesis, index: 1) {
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
}

class WhileStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.While]),
            WhileConditionSymbol(),
            CodeBlockSymbol()
        ]})
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
                assert(false, "Unexpected syntax error")
            }
        })
    }
}

/*
 * Branch statement
 */
class ElseClauseSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == .Else {
                if equalDFA(tp, .If, index: 1) {
                    return [TerminalSymbol([.Else]), CodeBlockSymbol()]
                } else if equalDFA(tp, .LeftBrace, index: 1) {
                    return [TerminalSymbol([.Else]), IfStatementSymbol()]
                }
            }
            return nil
        }, isOptional: isOptional)
    }
}

class IfConditionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ExpressionSymbol()] })
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
}

class BranchStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [ IfStatementSymbol() ]})
    }
}

/*
 * Labeled statement
 */
class LabelNameSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            if tp.look().kind == identifier {
                return [TerminalSymbol([identifier])]
            }
            return nil
        }, isOptional: isOptional)
    }
}

class StatementLabelSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            LabelNameSymbol(),
            TerminalSymbol([.Colon], errorGenerator: { [(.ExpectedColon, $0)] })
        ]})
    }
}

class LabeledStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementLabelSymbol(), LoopStatementSymbol()] });
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
}

class ContinueStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Continue]),
            LabelNameSymbol(isOptional: true)
        ]})
    }
}

class ReturnStatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol([.Return]),
            LabelNameSymbol(isOptional: true)
        ]})
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
                assert(false, "Unexpected syntax error")
            }
        })
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
                if equalDFA(tp, .Colon, index: 1) {
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
}

class StatementsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in 
            switch tp.look().kind {
            case .EndOfFile, .LineFeed, .Semicolon,
                 .Colon, .Comma, .Arrow, .Hash, .Dot,
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
}

/*
 * Top level declaration
 */
class TopLevelDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementsSymbol(isOptional: true)] })
    }
}

public class Parser {
    private let ts: TokenStream!

    init?(_ file: File) {
        ts = TokenStream(file)
        if ts == nil {
            return nil
        }
    }

    func parse() -> ParseResult {
        var errors: [Error] = []
        let stack: [Symbol] = [
            TopLevelDeclarationSymbol(),
            TerminalSymbol([.EndOfFile],
                           errorGenerator: { [(.ExpectedEndOfFile, $0)] })
        ]
        for element in stack {
            switch element.parse(ts) {
            case .Success:
                break
            case let .Failure(es):
                errors.extend(es)
            }
        }
        if errors.count > 0 {
            return .Failure(errors)
        } else {
            return .Success
        }
    }
}
