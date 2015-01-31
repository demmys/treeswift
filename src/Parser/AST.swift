import Util

public protocol ASTVisitor {
    func visit(TopLevelDeclaration)
}

public protocol AST {
    func accept(ASTVisitor)
}

class OptionalParts : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Terminal : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Identifier : AST {
    var value: IdentifierKind
    init(_ v: IdentifierKind) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class IntegerLiteral : AST {
    var value: Int
    init(_ v: Int) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class PrefixOperator : AST {
    var value: String
    init(_ v: String) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class PostfixOperator : AST {
    var value: String
    init(_ v: String) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class BinaryOperator : AST {
    var value: String
    init(_ v: String) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class AssignmentOperator : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Underscore : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Inout : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Hash : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

enum ValueClass : AST {
    case Var, Let
    func accept(_: ASTVisitor) {}
}

/*
 * Expression
 */
public enum ExpressionElement : AST {
    case Unnamed(Expression)
    case Named(IdentifierKind, Expression)
    public func accept(_: ASTVisitor) {}
}

class ExpressionElements : AST {
    var value: [ExpressionElement]
    init(_ v: [ExpressionElement]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class Identifiers : AST {
    var value: [IdentifierKind]
    init(_ v: [IdentifierKind]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public enum ClosureTypeClause : AST {
    case Typed(ParameterClause, Type?)
    case Untyped([IdentifierKind], Type?)
    public func accept(_: ASTVisitor) {}
}

enum CaptureSpecifier : AST {
    case Weak, Unowned
    func accept(_: ASTVisitor) {}
}

public class CaptureElement : AST {
    var specifier: CaptureSpecifier
    var element: Expression
    init(_ s: CaptureSpecifier, _ e: Expression) {
        specifier = s
        element = e
    }
    public func accept(_: ASTVisitor) {}
}

class CaptureElements : AST {
    var value: [CaptureElement]
    init(_ v: [CaptureElement]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class ClosureSignature : AST {
    var capture: [CaptureElement]?
    var type: ClosureTypeClause?
    init(_ c: [CaptureElement]?, _ t: ClosureTypeClause?) {
        capture = c
        type = t
    }
    func accept(_: ASTVisitor) {}
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
    public func accept(_: ASTVisitor) {}
}

public enum LiteralExpression : AST {
    case Integer(Int)
    case True, False, Nil
    case Array([Expression]?)
    public func accept(_: ASTVisitor) {}
}

public enum PrimaryExpression : AST {
    case Reference(IdentifierKind)
    case Value(LiteralExpression)
    case Closure(ClosureExpression)
    case Parenthesized([ExpressionElement])
    case Whildcard
    public func accept(_: ASTVisitor) {}
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
    public func accept(_: ASTVisitor) {}
}

class PostfixExpressions : AST {
    var value: [PostfixExpression]
    init(_ v: [PostfixExpression]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
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
    public func accept(_: ASTVisitor) {}
}

enum TypeCastingOperator : AST {
    case Is, As
    func accept(_: ASTVisitor) {}
}

public enum BinaryExpression : AST {
    case BinaryOperation(String, PrefixExpression)
    case AssignmentOperation(PrefixExpression)
    case ConditionalOperation(Expression, PrefixExpression)
    case IsOperation(Type)
    case AsOperation(Type)
    case OptionalAsOperation(Type)
    public func accept(_: ASTVisitor) {}
}

class BinaryExpressions : AST {
    var value: [BinaryExpression]
    init(_ v: [BinaryExpression]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public enum Expression : AST {
    case InOut(IdentifierKind)
    case Term(PrefixExpression, [BinaryExpression]?)
    public func accept(_: ASTVisitor) {}
}

class Expressions : AST {
    var value: [Expression]
    init(_ v: [Expression]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

/*
 * Types
 */
public class ArrayType {
    var value: Type
    init(_ v: Type) {
        value = v
    }
    public func accept(_: ASTVisitor) {}
}

public class FunctionType {
    var left: Type
    var right: Type
    init(_ l: Type, _ r: Type) {
        left = l
        right = r
    }
    func accept(_: ASTVisitor) {}
}

public class TupleTypeElement : AST {
    var isInout: Bool
    var name: IdentifierKind?
    var type: Type
    init(_ i: Bool, _ n: IdentifierKind?, _ t: Type) {
        isInout = i
        name = n
        type = t
    }
    public func accept(_: ASTVisitor) {}
}

class TupleTypeElements : AST {
    var value: [TupleTypeElement]
    init(_ v: [TupleTypeElement]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public enum Type : AST {
    case Single(IdentifierKind)
    case Tuple([TupleTypeElement]?)
    case Function(FunctionType)
    case Array(ArrayType)
    public func accept(_: ASTVisitor) {}
}

/*
 * Patterns
 */
class TuplePatternElements : AST {
    var value: [Pattern]?
    init(_ v: [Pattern]?) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public class PatternWrapper {
    var value: Pattern
    init(_ value: Pattern) {
        self.value = value
    }
    public func accept(_: ASTVisitor) {}
}

public enum BindingPattern : AST {
    case Variable(PatternWrapper)
    case Constant(PatternWrapper)
    public func accept(_: ASTVisitor) {}
}

public enum Pattern : AST {
    case Wildcard(Type?)
    case Variable(IdentifierKind, Type?)
    case ValueBinding(BindingPattern)
    case Tuple([Pattern]?, Type?)
    public func accept(_: ASTVisitor) {}
}

/*
 * Declaration
 */
public enum Associativity : AST {
    case Left, Right, None
    public func accept(_: ASTVisitor) {}
}

class InfixOperatorAttributes : AST {
    var precedence: Int?
    var associativity: Associativity?
    init(_ p: Int?, _ a: Associativity?) {
        precedence = p
        associativity = a
    }
    func accept(_: ASTVisitor) {}
}

class ParameterName : AST {
    var value: IdentifierKind?
    init(_ v: IdentifierKind?) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public class Parameter : AST {
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
    public func accept(_: ASTVisitor) {}
}

class Parameters : AST {
    var value: [Parameter]
    init(_ v: [Parameter]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public class ParameterClause : AST {
    var value: [Parameter]?
    init(_ v: [Parameter]?) {
        value = v
    }
    public func accept(_: ASTVisitor) {}
}

class ParameterClauses : AST {
    var value: [ParameterClause]
    init(_ v: [ParameterClause]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

class FunctionSignature : AST {
    var parameter: [ParameterClause]
    var result: Type?
    init(_ p: [ParameterClause], _ r: Type?) {
        parameter = p
        result = r
    }
    func accept(_: ASTVisitor) {}
}

enum FunctionName : AST {
    case Function(IdentifierKind)
    case Operator(String)
    func accept(_: ASTVisitor) {}
}

public class PatternInitializer : AST {
    var pattern: Pattern
    var initializer: Expression?
    init(_ p: Pattern, _ i: Expression?) {
        pattern = p
        initializer = i
    }
    public func accept(_: ASTVisitor) {}
}

class PatternInitializers : AST {
    var value: [PatternInitializer]
    init(_ v: [PatternInitializer]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
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
    public func accept(_: ASTVisitor) {}
}

/*
 * Statements
 */

public class StatementWrapper {
    var value: Statement
    init(_ value: Statement) {
        self.value = value
    }
    public func accept(_: ASTVisitor) {}
}
public enum ElseClause : AST {
    case Else([Statement]?)
    case ElseIf(StatementWrapper)
    public func accept(_: ASTVisitor) {}
}

public enum IfCondition : AST {
    case Term(Expression)
    public func accept(_: ASTVisitor) {}
}

public enum WhileCondition : AST {
    case Term(Expression)
    case Definition(Declaration)
    public func accept(_: ASTVisitor) {}
}

enum ForInit : AST {
    case VariableDeclaration(Declaration)
    case Terms([Expression])
    func accept(_: ASTVisitor) {}
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
    public func accept(_: ASTVisitor) {}
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
    public func accept(_: ASTVisitor) {}
}

class Statements : AST {
    var value: [Statement]
    init(_ v: [Statement]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

/*
 * Top level declaration
 */
public class TopLevelDeclaration : AST {
    var value: [Statement]?
    init(_ v: [Statement]?) {
        value = v
    }
    public func accept(visitor: ASTVisitor) {
        visitor.visit(self)
    }
}
