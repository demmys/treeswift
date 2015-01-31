import Util

public protocol ASTVisitor {
    func visit(ast: TopLevelDeclaration)
    func visit(ast: Statement)
    func visit(ast: CaptureElement)
    func visit(ast: ClosureExpression)
    func visit(ast: PrimaryExpression)
    func visit(ast: PostfixExpression)
    func visit(ast: PrefixExpression)
    func visit(ast: BinaryExpression)
    func visit(ast: Expression)
    func visit(ast: Type)
    func visit(ast: BindingPattern)
    func visit(ast: Pattern)
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
    init() {}
}

class Identifier : ASTParts {
    var value: IdentifierKind

    init(_ v: IdentifierKind) {
        value = v
    }
}

class IntegerLiteral : ASTParts {
    var value: Int

    init(_ v: Int) {
        value = v
    }
}

class PrefixOperator : ASTParts {
    var value: String

    init(_ v: String) {
        value = v
    }
}

class PostfixOperator : ASTParts {
    var value: String

    init(_ v: String) {
        value = v
    }
}

class BinaryOperator : ASTParts {
    var value: String

    init(_ v: String) {
        value = v
    }
}

class AssignmentOperator : ASTParts {
    init() {}
}

class Underscore : ASTParts {
    init() {}
}

class Inout : ASTParts {
    init() {}
}

class Hash : ASTParts {
    init() {}
}

enum ValueClass : ASTParts {
    case Var, Let
}

/*
 * Expression
 */
public enum ExpressionElement : ASTParts {
    case Unnamed(Expression)
    case Named(IdentifierKind, Expression)
}

class ExpressionElements : ASTParts {
    var value: [ExpressionElement]

    init(_ v: [ExpressionElement]) {
        value = v
    }
}

class Identifiers : ASTParts {
    var value: [IdentifierKind]

    init(_ v: [IdentifierKind]) {
        value = v
    }
}

public enum ClosureTypeClause : ASTParts {
    case Typed(ParameterClause, Type?)
    case Untyped([IdentifierKind], Type?)
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

class ClosureSignature : ASTParts {
    var capture: [CaptureElement]?
    var type: ClosureTypeClause?

    init(_ c: [CaptureElement]?, _ t: ClosureTypeClause?) {
        capture = c
        type = t
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

public enum LiteralExpression : ASTParts {
    case Integer(Int)
    case True, False, Nil
    case Array([Expression]?)
}

public enum PrimaryExpression : AST {
    case Reference(IdentifierKind)
    case Value(LiteralExpression)
    case Closure(ClosureExpression)
    case Parenthesized([ExpressionElement])
    case Whildcard

    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum MemberExpression {
    case Named(IdentifierKind)
    case Unnamed(Int)
}

public enum PostfixExpression : AST {
    case PostfixOperation(String)
    case FunctionCall([ExpressionElement], ClosureExpression?)
    case ExplicitMember(MemberExpression)
    case Subscript([Expression])

    public func accept(v: ASTVisitor) { v.visit(self) }
}

class PostfixExpressions : ASTParts {
    var value: [PostfixExpression]

    init(_ v: [PostfixExpression]) {
        value = v
    }
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

enum TypeCastingOperator : ASTParts {
    case Is, As
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
    case InOut(IdentifierKind)
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
public class ArrayType {
    var value: Type

    init(_ v: Type) {
        value = v
    }
}

public class FunctionType {
    var left: Type
    var right: Type

    init(_ l: Type, _ r: Type) {
        left = l
        right = r
    }
}

public class TupleTypeElement : ASTParts {
    var isInout: Bool
    var name: IdentifierKind?
    var type: Type

    init(_ i: Bool, _ n: IdentifierKind?, _ t: Type) {
        isInout = i
        name = n
        type = t
    }
}

class TupleTypeElements : ASTParts {
    var value: [TupleTypeElement]

    init(_ v: [TupleTypeElement]) {
        value = v
    }
}

public enum Type : AST {
    case Single(IdentifierKind)
    case Tuple([TupleTypeElement]?)
    case Function(FunctionType)
    case Array(ArrayType)

    public func accept(v: ASTVisitor) { v.visit(self) }
}

/*
 * Patterns
 */
class TuplePatternElements : ASTParts {
    var value: [Pattern]?

    init(_ v: [Pattern]?) {
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
    case Variable(IdentifierKind, Type?)
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

class InfixOperatorAttributes : ASTParts {
    var precedence: Int?
    var associativity: Associativity?

    init(_ p: Int?, _ a: Associativity?) {
        precedence = p
        associativity = a
    }
}

class ParameterName : ASTParts {
    var value: IdentifierKind?

    init(_ v: IdentifierKind?) {
        value = v
    }
}

public class Parameter : ASTParts {
    var isInout: Bool
    var isConstant: Bool
    var externalName: IdentifierKind?
    var localName: IdentifierKind?
    var type: Type
    var defaultArgument: Expression?

    init(_ i: Bool, _ c: Bool, _ e: IdentifierKind?,
         _ l: IdentifierKind?, _ t: Type, _ d: Expression?) {
        isInout = i
        isConstant = c
        externalName = e
        localName = l
        type = t
        defaultArgument = d
    }
}

class Parameters : ASTParts {
    var value: [Parameter]

    init(_ v: [Parameter]) {
        value = v
    }
}

public class ParameterClause : ASTParts {
    var value: [Parameter]?

    init(_ v: [Parameter]?) {
        value = v
    }
}

class ParameterClauses : ASTParts {
    var value: [ParameterClause]

    init(_ v: [ParameterClause]) {
        value = v
    }
}

class FunctionSignature : ASTParts {
    var parameter: [ParameterClause]
    var result: Type?

    init(_ p: [ParameterClause], _ r: Type?) {
        parameter = p
        result = r
    }
}

enum FunctionName : ASTParts {
    case Function(IdentifierKind)
    case Operator(String)
}

public class PatternInitializer : ASTParts {
    var pattern: Pattern
    var initializer: Expression?

    init(_ p: Pattern, _ i: Expression?) {
        pattern = p
        initializer = i
    }
}

class PatternInitializers : ASTParts {
    var value: [PatternInitializer]

    init(_ v: [PatternInitializer]) {
        value = v
    }
}

public enum Declaration : AST {
    case Constant([PatternInitializer])
    case Variable([PatternInitializer])
    case Typealias(IdentifierKind, Type)
    case Function(IdentifierKind, [ParameterClause], Type?, [Statement]?)
    case OperatorFunction(String, [ParameterClause], Type?, [Statement]?)
    case PrefixOperator(String)
    case PostfixOperator(String)
    case InfixOperator(String, Int?, Associativity?)
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
    case For(ForCondition, [Statement]?, IdentifierKind?)
    case ForIn(Pattern, Expression, [Statement]?, IdentifierKind?)
    case While(WhileCondition, [Statement]?, IdentifierKind?)
    case DoWhile(WhileCondition, [Statement]?, IdentifierKind?)
    // branch-statement
    case If(IfCondition, [Statement]?, ElseClause?)
    // control-transfer-statement
    case Break(IdentifierKind?)
    case Continue(IdentifierKind?)
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
