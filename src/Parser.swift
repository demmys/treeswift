protocol Symbol {
    var errorInfo: [ErrorInfo] { get }
    func parse(input: TokenStream) -> Bool
}

class TerminalSymbol : Symbol {
    private let kinds: [TokenKind]

    private var errorInfo_: ErrorInfo
    var errorInfo: [ErrorInfo]  {
        get {
            return [errorInfo_]
        }
    }

    init(kinds: [TokenKind], errorMessage: String) {
        self.kinds = kinds
        errorInfo_ = ErrorInfo(reason: errorMessage)
    }

    func parse(input: TokenStream) -> Bool {
        var token: Token
        do {
            token = input.look()
            input.next()
        } while isMeaningless(token.kind)

        for kind in kinds {
            if token.kind == kind {
                println("TerminalSymbol\t->\ttrue")
                return true
            }
        }
        errorInfo_.lineNo = token.lineNo
        errorInfo_.charNo = token.charNo
        errorInfo_.source = token.source
        println("TerminalSymbol-> false")
        return false
    }

    private func isMeaningless(target: TokenKind) -> Bool {
        switch target {
        case .Space:
            for k in kinds {
                if k == .Space {
                    return false
                }
            }
            return true
        case .LineFeed:
            for k in kinds {
                if k == .LineFeed || k == .Space {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}

class NonTerminalSymbol : Symbol {
    private var ruleArbiter: TokenPeeper -> [Symbol]?
    private var isOptional: Bool

    private var errorInfo_: [ErrorInfo]
    var errorInfo: [ErrorInfo] {
        get {
            return errorInfo_
        }
    }

    /*
     * `ruleArbiter` is DFA, which decides the rule that will be applied or
     * returns nil when there's no rule to apply to
     */
    init(_ ruleArbiter: TokenPeeper -> [Symbol]?, isOptional: Bool = false) {
        self.ruleArbiter = ruleArbiter
        self.isOptional = isOptional
        errorInfo_ = []
    }

    func parse(input: TokenStream) -> Bool {
        if let elements = ruleArbiter(input) {
            for element in elements {
                if !element.parse(input) {
                    errorInfo_.extend(element.errorInfo)
                    println("parse failed with \(reflect(element).summary)")
                }
            }
            println("\(reflect(self).summary)\t->\t\(errorInfo_.count == 0)")
            return errorInfo_.count == 0
        } else if isOptional {
            return true
        }
        println("\(reflect(self).summary)\t->\tfalse")
        return false
    }
}

/*
 * literal -> Space* IntegerLiteral
 */
class LiteralSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [TerminalSymbol(
            kinds: [.IntegerLiteral(0)],
            errorMessage: "Expected integer literal"
        )] })
    }
}

/*
 * literal-expression -> literal
 */
class LiteralExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [LiteralSymbol()] })
    }
}

/*
 * primary-expression -> literal-expression
 */
class PrimaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [LiteralExpressionSymbol()] })
    }
}

/*
 * postfix-operator -> Operator \ze [(Space | LineFeed | EndOfFile)]
 */
class PostfixOperatorSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            if tp.look().kind == .Operator("") {
                switch tp.look(1).kind! {
                case .Space, .LineFeed, .EndOfFile:
                    return [TerminalSymbol(
                        kinds: [.Operator("")],
                        errorMessage: "Expected postfix operator"
                    )]
                default:
                    return nil
                }
            }
            return nil
        })
    }
}

/*
 * LL(k) (optional)
 * postfix-expression-tail -> postfix-operator postfix-expression-tail
 */
class PostfixExpressionTailSymbol : NonTerminalSymbol {
    init(isOptional: Bool) {
        super.init({ tp in
            switch tp.look().kind! {
            case .Operator:
                return [
                    PostfixOperatorSymbol(),
                    PostfixExpressionTailSymbol()
                ]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }
    convenience init() {
        self.init(isOptional: false)
    }
}

/*
 * postfix-expression -> primary-expression postfix-expression-tail?
 */
class PostfixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrimaryExpressionSymbol(),
            PostfixExpressionTailSymbol(isOptional: true)
        ]})
    }
}

/*
 * LL(k) (optional)
 * prefix-operator -> Space* Operator \ze [^(Space | LineFeed | EndOfFile)]
 */
class PrefixOperatorSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            var i: Int
            for i = 0; tp.look(i).kind == .Space; ++i {}
            if tp.look(i).kind == .Operator("") {
                switch tp.look(i + 1).kind! {
                case .Space, .LineFeed, .EndOfFile:
                    return nil
                default:
                    return [TerminalSymbol(
                        kinds: [.Operator("")],
                        errorMessage: "Expected prefix operator"
                    )]
                }
            }
            return nil
        })
    }
}

/*
 * prefix-expression -> prefix-operator? postfix-expression
 */
class PrefixExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrefixOperatorSymbol(isOptional: true),
            PostfixExpressionSymbol()
        ]})
    }
}

/*
 * LL(1)
 * binary-operator -> Space+ Operator Space
 *                 -> Operator
 */
class BinaryOperatorSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in
            switch tp.look().kind! {
            case .Space:
                return [TerminalSymbol(
                    kinds: [.Space],
                    errorMessage: "Space existence before and after Binary operator should be unified"
                ), TerminalSymbol(
                    kinds: [.Operator("")],
                    errorMessage: "Operator literal expected"
                ), TerminalSymbol(
                    kinds: [.Space],
                    errorMessage: "Space existence before and after Binary operator should be unified"
                )]
            case .Operator:
                return [TerminalSymbol(
                    kinds: [.Operator("")],
                    errorMessage: "Expected operator"
                )]
            default:
                return nil
            }
        })
    }
}

/*
 * binary-expression -> binary-operator prefix-expression
 */
class BinaryExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [BinaryOperatorSymbol(), PrefixExpressionSymbol()]})
    }
}

/*
 * LL(k) (optional)
 * binary-expressions -> binary-expression binary-expressions?
 */
class BinaryExpressionsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in
            switch tp.look().kind! {
            case .Space:
                var i: Int
                for i = 1; tp.look(i).kind == .Space; ++i {}
                if tp.look(i).kind == .Operator("") {
                    fallthrough
                }
                return nil
            case .Operator:
                return [
                    BinaryExpressionSymbol(),
                    BinaryExpressionsSymbol(isOptional: true)
                ]
            default:
                return nil
            }
        }, isOptional: isOptional)
    }
}

/*
 * expression -> prefix-expression binary-expressions?
 */
class ExpressionSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            PrefixExpressionSymbol(),
            BinaryExpressionsSymbol(isOptional: true)
        ]})
    }
}

/*
 * statement -> expression Space* (LineFeed | Semicolon | EndOfFile)
 */
class StatementSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [
            ExpressionSymbol(),
            TerminalSymbol(kinds: [.LineFeed, .Semicolon, .EndOfFile],
                           errorMessage: "Expected line feed or semicolon at the end of statement")
        ]})
    }
}

/*
 * LL(k) (optional)
 * statements -> (Space | LineFeed)* statement statements?
 */
class StatementsSymbol : NonTerminalSymbol {
    init(isOptional: Bool = false) {
        super.init({ tp in 
            var i = -1
            var target = tp.look(0).kind
            do {
                target = tp.look(++i).kind
            } while target == .Space || target == .LineFeed
            switch tp.look(i).kind! {
            case .Semicolon, .EndOfFile:
                return nil
            default:
                return [StatementSymbol(), StatementsSymbol(isOptional: true)]
            }
        }, isOptional: isOptional)
    }
}

/*
 * top-level-declaration -> statements?
 */
class TopLevelDeclarationSymbol : NonTerminalSymbol {
    init() {
        super.init({ tp in [StatementsSymbol(isOptional: true)] })
    }
}

public class Parser {
    private let ts: TokenStream!
    private var errors_: [ErrorInfo]
    var errors: [ErrorInfo] {
        get {
            return errors_
        }
    }

    init?(_ file: File) {
        errors_ = []
        ts = TokenStream(file)
        if ts == nil {
            return nil
        }
    }

    func parse() -> Bool {
        errors_ = []
        let stack: [Symbol] = [
            TopLevelDeclarationSymbol(),
            TerminalSymbol(kinds: [.EndOfFile],
                           errorMessage: "Expected end of file")
        ]
        for element in stack {
            if !element.parse(ts) {
                errors_.extend(element.errorInfo)
            }
        }
        return errors_.count == 0
    }
}
