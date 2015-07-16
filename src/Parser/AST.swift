import Util

class OptionalParts : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Terminal : AST {
    init() {}
    func accept(_: ASTVisitor) {}
}

class Identifier : AST {
    var value: String
    init(_ v: String) {
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

class InOut : AST {
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
 * Expressions
 */
public enum ExpressionElement : AST {
    case Unnamed(Expression)
    case Named(String, Expression)
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
    var value: [String]
    init(_ v: [String]) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public enum ClosureTypeClause : AST {
    case Typed(ParameterClause, Type?)
    case Untyped([String], Type?)
    public func accept(_: ASTVisitor) {}
}

public enum CaptureSpecifier : AST {
    case Weak, Unowned
    public func accept(_: ASTVisitor) {}
}

public class CaptureElement : AST {
    public var specifier: CaptureSpecifier
    public var element: Expression
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
    public var capture: [CaptureElement]?
    public var type: ClosureTypeClause?
    public var body: [Statement]
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
    public func accept(v: ASTVisitor) { v.visit(self) }
}

public enum PrimaryExpression : AST {
    case Reference(String)
    case Value(LiteralExpression)
    case Closure(ClosureExpression)
    case Parenthesized([ExpressionElement])
    case Whildcard
    public func accept(_: ASTVisitor) {}
}

public enum MemberExpression {
    case Named(String)
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
    public var op: String?
    public var head: PrimaryExpression
    public var tail: [PostfixExpression]?
    init(_ o: String?, _ h: PrimaryExpression, _ t: [PostfixExpression]?) {
        op = o
        head = h
        tail = t
    }
    public func accept(v: ASTVisitor) { v.visit(self) }
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
    case InOut(String)
    case Term(PrefixExpression, [BinaryExpression]?)
    public func accept(v: ASTVisitor) { v.visit(self) }
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
    public var value: Type
    init(_ v: Type) {
        value = v
    }
    public func accept(_: ASTVisitor) {}
}

public class ArrowType {
    public var left: Type
    public var right: Type
    init(_ l: Type, _ r: Type) {
        left = l
        right = r
    }
    func accept(_: ASTVisitor) {}
}

public class TupleTypeElement : AST {
    public var isInOut: Bool
    public var name: String?
    public var type: Type
    init(_ i: Bool, _ n: String?, _ t: Type) {
        isInOut = i
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
    case Single(String)
    case Tuple([TupleTypeElement]?)
    case Function(ArrowType)
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
    public var value: Pattern
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
    case Variable(String, Type?)
    case ValueBinding(BindingPattern)
    case Tuple([Pattern]?, Type?)
    public func accept(_: ASTVisitor) {}
}

/*
 * Declarations
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
    var value: String?
    init(_ v: String?) {
        value = v
    }
    func accept(_: ASTVisitor) {}
}

public class Parameter : AST {
    public var isInOut: Bool
    public var isConstant: Bool
    public var externalName: String?
    public var localName: String?
    public var type: Type
    public var defaultArgument: Expression?
    init(_ i: Bool, _ c: Bool, _ e: String?,
         _ l: String?, _ t: Type, _ d: Expression?) {
        isInOut = i
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
    public var value: [Parameter]?
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
    case Function(String)
    case Operator(String)
    func accept(_: ASTVisitor) {}
}

public class PatternInitializer : AST {
    public var pattern: Pattern
    public var initializer: Expression?
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

public enum ImportKind {
    case Typealias, Struct, Class, Enum, Protocol, Var, Func
}

public enum Declaration : AST {
    case Constant([PatternInitializer])
    case Variable([PatternInitializer])
    case Typealias(String, Type)
    case Function(String, [ParameterClause], Type?, [Statement]?)
    case OperatorFunction(String, [ParameterClause], Type?, [Statement]?)
    case PrefixOperator(String)
    case PostfixOperator(String)
    case InfixOperator(String, Int?, Associativity?)
    public func accept(v: ASTVisitor) { v.visit(self) }
}

/*
 * Statements
 */
public enum Statement {
    case Expression(Expression)
    case Declaration(Declaration)
    // loop-statement, labeled-statement
    case For(ForCondition, [Statement]?, String?)
    case ForIn(Pattern, Expression, [Statement]?, String?)
    case While(WhileCondition, [Statement]?, String?)
    case DoWhile(WhileCondition, [Statement]?, String?)
    // branch-statement
    case If(IfCondition, [Statement]?, ElseClause?)
    // control-transfer-statement
    case Break(IdentifierKind?)
    case Continue(IdentifierKind?)
    case Fallthrough
    case Return(Expression?)
    case Throw(Expression?)
    // defer-statement
    case Defer([Statement]?)
    // do-statement
    case Do()
}

enum Condition {
    enum BindingType {
        case Let, Var
    }

    case Case(Pattern, Expression, Expression?)
    case Optional([(BindingType?, Pattern, Expression)], Expression?)
}

/*
 * Top level declaration
 */
public struct TopLevelDeclaration {
    public let ss: [Statement] = []
    public let main: Bool
}
