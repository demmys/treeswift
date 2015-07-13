/*
 * top level declaration
 */
class TopLevelDeclarationBuilder {
    private var ss: [Statement] = []
    private var main = false

    func add(s: Statement) {
        switch s {
        case .Declaration:
            ss.append(s)
        default:
            main = true
            ss.append(s)
        }
    }

    func build() -> TopLevelDeclaration {
        return TopLevelDeclaration(ss: ss, main: main)
    }
}

/*
 * control statement
 */
class ControlStatementBuilder {
    var label: IdentifierKind?
    var cond: ControlStatementBuilderCondition!
    var body: [Statement]!

    func build() -> Statement {
    }
}

enum ControlStatementBuilderCondition {
    case For(ForStatementCondition)
    case ForIn(ForInStatementCondition)
    case While(Expression, [Condition]?)
    case RepeatWhile(Expression)
    case If(IfStatementCondition)
    case Guard(Expression?, [Condition]?)
}

class ForStatementCondition {
    enum PrepareStatement {
        case Declaration(Declaration)
        case Expressions([Expression])
    }

    var pre: PrepareStatement?
    var cond: Expression?
    var post: [Expression]?
}

class ForInStatementCondition {
    enum RepeatPattern {
        case normal(Pattern)
        case switchCase(Pattern)
    }

    var pat: RepeatPattern!
    var src: Expression!
    var filter: Expression?
}

class IfStatementCondition {
    enum ElseStatement {
        case CodeBlock([Statement])
        case IfStatement(Statement)
    }

    var condExp: Expression?
    var conds: [Condition]?
    var els: ElseStatement?
}

class SwitchStatementCondition {
    struct CaseItem {
        var pat: Pattern!
        var filter: Expression?
    }

    struct SwitchCase {
        var label: [CaseItem]?
        var body: [Statements]?
    }

    var cond: Expression!
    var cases: [SwitchCase]!
}

class DoStatementCondition {
    struct CatchClause {
        var pat: Pattern?
        var filter: Expression?
        var body: [Statement]!
    }

    var body: [Statement]!
    var catches: [CatchClause]?

    func build() -> Statement {
    }
}

class CaseConditionBuilder {
    var pat: Pattern!
    var exp: Expression!
    var filter: Expression?

    func build() -> Condition {
        return .Case(pat, exp, filter)
    }
}

class OptionalConditionBuilder {
    struct OptionalBinding {
        var type: Condition.BindingType?
        var pat: Pattern!
        var exp: Expression!
    }

    var binds: [OptionalBinding] = []
    var filter: Expression?

    func build() -> Condition {
        var bs: [(BindingType?, Pattern, Expression)]
        for b in binds {
            bs.append(b.type, b.pat, b.exp)
        }
        return .Optional(bs, filter)
    }
}

/*
 * declaration
 */
class DeclarationBuilder {
    var attrs: [String]?
    var mods: [ModifierKind]?
}
