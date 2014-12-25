typealias Error = (ErrorMessage, SourceInfo)

enum ParseResult {
    case Success
    case Failure([Error])
}

protocol Symbol {
    func parse(TokenStream) -> ParseResult
}

class TerminalSymbol : Symbol {
    private let kinds: [TokenKind]
    private var errorGenerator: SourceInfo -> [Error]
    private var isOptional: Bool

    init(kinds: [TokenKind], errorGenerator: SourceInfo -> [Error],
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
        return .Failure(errorGenerator(inputToken.info))
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

class LiteralSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol(kinds: [.IntegerLiteral(0, decimalDigit: false)], errorGenerator: {
                [(.ExpectedIntegerLiteral, $0)]
            })
        ]})
    }
}

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
                TerminalSymbol(kinds: [.LeftParenthesis], errorGenerator: {
                    [(.ExpectedLeftParenthesis, $0)]
                }),
                ExpressionSymbol(),
                TerminalSymbol(kinds: [.RightParenthesis], errorGenerator: {
                    [(.ExpectedRightParenthesis, $0)]
                })
            ]
        })
    }
}


class PostfixExpressionTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool) {
        super.init({ tp in
            if tp.look().kind != .PostfixOperator("") {
                return nil
            }
            return [
                TerminalSymbol(kinds: [.PostfixOperator("")], errorGenerator: {
                    [(.ExpectedPostfixOperator, $0)]
                }),
                PostfixExpressionTailSymbol(isOptional: true)
            ]
        }, isOptional: isOptional)
    }
    convenience init() {
        self.init(isOptional: false)
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
            TerminalSymbol(kinds: [.PrefixOperator("")], errorGenerator: {
                [(.ExpectedPrefixOperator, $0)]
            }, isOptional: true),
            PostfixExpressionSymbol()
        ]})
    }
}


class BinaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            TerminalSymbol(kinds: [.BinaryOperator("")], errorGenerator: {
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

class StatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ExpressionSymbol(),
            TerminalSymbol(kinds: [.LineFeed, .Semicolon, .EndOfFile],
                           errorGenerator: { [(.ExpectedEndOfStatement, $0)] })
        ]})
    }
}

class StatementsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in 
            var kind = tp.look().kind
            if kind == .LineFeed {
                kind = tp.look(1).kind
            }
            switch kind {
            case .Semicolon, .EndOfFile:
                return nil
            default:
                return [StatementSymbol(), StatementsSymbol(isOptional: true)]
            }
        }, isOptional: isOptional)
    }
}

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
            TerminalSymbol(kinds: [.EndOfFile], errorGenerator: {
                [(.ExpectedEndOfFile, $0)]
            })
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
