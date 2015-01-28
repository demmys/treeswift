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

struct OptionalParts : ASTParts {}

struct Terminal : ASTParts {
    let token: Token
}

public struct Identifier : ASTParts {
    var value: IdentifierKind
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

struct ExpressionElements : ASTParts {
    var value: [ExpressionElement]
}

struct Identifiers : ASTParts {
    var value: [Identifier]
}

public enum ClosureTypeClause : AST {
    case Typed(ParameterClause, Type?)
    case Untyped([Identifier], Type?)
    public func accept(v: ASTVisitor) { v.visit(self) }
}

enum CaptureSpecifier : ASTParts {
    case Weak, Unowned
}

public struct CaptureElement : AST {
    var specifier: CaptureSpecifier
    var element: Expression
    public func accept(v: ASTVisitor) { v.visit(self) }
}

struct CaptureElements : ASTParts {
    var value: [CaptureElement]
}

public struct ClosureExpression : AST {
    var capture: [CaptureElement]?
    var type: ClosureTypeClause?
    var body: [Statement]
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
    init(op: String?, head: PrimaryExpression, tail: [PostfixExpression]?) {
        self.op = op
        self.head = head
        self.tail = tail
    }
    public func accept(v: ASTVisitor) { v.visit(self) }
}

struct PostfixExpressions : ASTParts {
    var value: [PostfixExpression]
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

struct BinaryExpressions : ASTParts {
    var value: [BinaryExpression]
}

public enum Expression : AST {
    case InOut(Identifier)
    case Term(PrefixExpression, [BinaryExpression]?)
    public func accept(v: ASTVisitor) { v.visit(self) }
}

struct Expressions : ASTParts {
    var value: [Expression]
}

/*
 * Types
 */
public struct TupleTypeElement : AST {
    var isInout: Bool
    var name: Identifier?
    var type: Type
    public func accept(v: ASTVisitor) { v.visit(self) }
}

struct TupleTypeElements : ASTParts {
    var value: [TupleTypeElement]
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
struct TuplePatternElement : ASTParts {
    var value: [Pattern]
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

public struct ParameterClause : AST {
    var isInout: Bool
    var isConstant: Bool
    var externalName: Identifier?
    var localName: Identifier?
    var type: Type
    var defaultArgument: Expression?
    public func accept(v: ASTVisitor) { v.visit(self) }
}

struct ParameterClauses : ASTParts {
    var value: [ParameterClause]
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

public struct ForCondition : AST {
    var initial: ForInit?
    var condition: Expression?
    var finalize: Expression?
    public func accept(v: ASTVisitor) { v.visit(self) }
}

struct Statements : ASTParts {
    var value: [Statement]
}

/*
 * Top level declaration
 */
public struct TopLevelDeclaration : AST {
    var statements: [Statement]?
    public func accept(v: ASTVisitor) { v.visit(self) }
}
