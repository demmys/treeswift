import Util

public protocol ASTVisitor {
    func visit(ast: TopLevelDeclaration)
    func visit(ast: Statement)
    func visit(ast: Literal)
    func visit(ast: ExpressionElement)
    func visit(ast: ClosureTypeClause)
    func visit(ast: CaptureElement)
    func visit(ast: ClosureExpression)
    func visit(ast: PrimaryExpression)
    func visit(ast: PostfixExpression)
    func visit(ast: PrefixExpression)
    func visit(ast: BinaryExpression)
    func visit(ast: Expression)
    func visit(ast: ArrayType)
    func visit(ast: FunctionType)
    func visit(ast: TupleTypeElement)
    func visit(ast: Type)
    func visit(ast: BindingPattern)
    func visit(ast: Pattern)
    func visit(ast: ParameterClause)
    func visit(ast: Declaration)
    func visit(ast: ElseClause)
    func visit(ast: IfCondition)
    func visit(ast: WhileCondition)
    func visit(ast: ForCondition)
}

public protocol ASTParts {}

public protocol AST : ASTParts {
    func accept(v: ASTVisitor)
}

class OptionalParts : ASTParts {
    init() {}
}

class Terminal : ASTParts {
    let value: Token

    init(_ v: Token) {
        value = v
    }
}

public class Identifier : ASTParts {
    var value: IdentifierKind

    init(_ v: IdentifierKind) {
        value = v
    }
}

/*
 * Literals
 */
public enum Literal : AST {
    case Integer(Int)
    case True, False, Nil

    public func accept(v: ASTVisitor) { v.visit(self) }
}


/*
 * Expression
 */
public enum ExpressionElement : AST {
    case Unnamed(Expression)
    case Named(Identifier, Expression)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class ExpressionElements : ASTParts {
    var value: [ExpressionElement]

    init(_ v: [ExpressionElement]) {
        value = v
    }
}

class Identifiers : ASTParts {
    var value: [Identifier]

    init(_ v: [Identifier]) {
        value = v
    }
}

public enum ClosureTypeClause : AST {
    case Typed(ParameterClause, Type?)
    case Untyped([Identifier], Type?)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

enum CaptureSpecifier : ASTParts {
    case Weak, Unowned
}

public class CaptureElement : AST {
    var specifier: CaptureSpecifier
    var element: Expression

    init(_ s: CaptureSpecifier, _ e: Expression) {
        specifier = s
        element = e
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class CaptureElements : ASTParts {
    var value: [CaptureElement]

    init(_ v: [CaptureElement]) {
        value = v
    }
}

public class ClosureExpression : AST {
    var capture: [CaptureElement]?
    var type: ClosureTypeClause?
    var body: [Statement]

    init(_ c: [CaptureElement]?, _ t: ClosureTypeClause?, _ b: [Statement]) {
        capture = c
        type = t
        body = b
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum PrimaryExpression : AST {
    case Reference(Identifier)
    case Value(Literal)
    case Closure(ClosureExpression)
    case Parenthesized([ExpressionElement])
    case Whildcard

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum MemberExpression {
    case Named(Identifier)
    case Unnamed(Int)
}

public enum PostfixExpression : AST {
    case PostfixOperation(String)
    case FunctionCall([ExpressionElement], ClosureExpression?)
    case ExplicitMember(MemberExpression)
    case Subscript([Expression])

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public class PrefixExpression : AST {
    var op: String?
    var head: PrimaryExpression
    var tail: [PostfixExpression]?

    init(_ o: String?, _ h: PrimaryExpression, _ t: [PostfixExpression]?) {
        op = o
        head = h
        tail = t
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class PostfixExpressions : ASTParts {
    var value: [PostfixExpression]

    init(_ v: [PostfixExpression]) {
        value = v
    }
}

public enum BinaryExpression : AST {
    case BinaryOperation(String, PrefixExpression)
    case AssignmentOperation(PrefixExpression)
    case ConditionalOperation(Expression, PrefixExpression)
    case IsOperation(Type)
    case AsOperation(Type)
    case OptionalAsOperation(Type)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class BinaryExpressions : ASTParts {
    var value: [BinaryExpression]

    init(_ v: [BinaryExpression]) {
        value = v
    }
}

public enum Expression : AST {
    case InOut(Identifier)
    case Term(PrefixExpression, [BinaryExpression]?)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class Expressions : ASTParts {
    var value: [Expression]

    init(_ v: [Expression]) {
        value = v
    }
}

/*
 * Types
 */
public class TupleTypeElement : AST {
    var isInout: Bool
    var name: Identifier?
    var type: Type

    init(_ i: Bool, _ n: Identifier?, _ t: Type) {
        isInout = i
        name = n
        type = t
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class TupleTypeElements : ASTParts {
    var value: [TupleTypeElement]

    init(_ v: [TupleTypeElement]) {
        value = v
    }
}

public enum Type : AST {
    case Single(Identifier)
    case Tuple([TupleTypeElement])
    case Function([FunctionType])
    case Array(ArrayType)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

/*
 * Patterns
 */
class TuplePatternElement : ASTParts {
    var value: [Pattern]

    init(_ v: [Pattern]) {
        value = v
    }
}

public class PatternWrapper {
    var value: Pattern

    init(_ value: Pattern) {
        self.value = value
    }
}

public enum BindingPattern : AST {
    case Variable(PatternWrapper)
    case Constant(PatternWrapper)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum Pattern : ASTParts {
    case Wildcard(Type?)
    case Variable(Identifier, Type?)
    case ValueBinding(BindingPattern)
    case Tuple([Pattern]?, Type?)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

/*
 * Declaration
 */
public enum Associativity : ASTParts {
    case Left, Right, None
}

public class ParameterClause : AST {
    var isInout: Bool
    var isConstant: Bool
    var externalName: Identifier?
    var localName: Identifier?
    var type: Type
    var defaultArgument: Expression?

    init(_ i: Bool, _ c: Bool, _ e: Identifier?,
         _ l: Identifier?, _ t: Type, _ d: Expression?) {
        isInout = i
        isConstant = c
        externalName = e
        localName = l
        type = t
        defaultArgument = d
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class ParameterClauses : ASTParts {
    var value: [ParameterClause]

    init(_ v: [ParameterClause]) {
        value = v
    }
}

public enum Declaration : AST {
    case Constant([(Pattern, Expression?)])
    case Variable([(Pattern, Expression?)])
    case Typealias(Identifier, Type)
    case Function(Identifier, [ParameterClause], Type?, [Statement]?)
    case OperatorFunction(String, [ParameterClause], Type?, [Statement]?)
    case PrefixOperator(String)
    case PostfixOperator(String)
    case InfixOperator(String, Int, Associativity)
    public func accept(v: ASTVisitor) { v.visit(self) }
}

/*
 * Statements
 */

public class StatementWrapper {
    var value: Statement

    init(_ value: Statement) {
        self.value = value
    }
}
public enum ElseClause : AST {
    case Else([Statement]?)
    case ElseIf(StatementWrapper)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum IfCondition : AST {
    case Term(Expression)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum WhileCondition : AST {
    case Term(Expression)
    case Definition(Declaration)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

enum ForInit : ASTParts {
    case VariableDeclaration(Declaration)
    case Terms([Expression])
}

public enum Statement : AST {
    case Term(Expression)
    case Definition(Declaration)
    // loop-statement, labeled-statement
    case For(ForCondition, [Statement]?, Identifier?)
    case ForIn(Pattern, Expression, [Statement]?, Identifier?)
    case While(WhileCondition, [Statement]?, Identifier?)
    case DoWhile(WhileCondition, [Statement]?, Identifier?)
    // branch-statement
    case If(IfCondition, [Statement]?, ElseClause?)
    // control-transfer-statement
    case Break(Identifier?)
    case Continue(Identifier?)
    case Return(Expression?)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public class ForCondition : AST {
    var initial: ForInit?
    var condition: Expression?
    var finalize: Expression?

    init(_ i: ForInit?, _ c: Expression?, _ f: Expression?) {
        initial = i
        condition = c
        finalize = f
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class Statements : ASTParts {
    var value: [Statement]

    init(_ v: [Statement]) {
        value = v
    }
}

/*
 * Top level declaration
 */
public class TopLevelDeclaration : AST {
    var value: [Statement]?

    init(_ v: [Statement]?) {
        value = v
    }

    public func accept(v: ASTVisitor) { v.visit(self) }
}
