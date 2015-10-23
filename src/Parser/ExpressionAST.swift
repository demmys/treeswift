public class Expression {
    var tryType: TryType!
    var body: ExpressionBody!
}

public enum TryType : String {
    case Nothing, Try, ForcedTry
}

public class ExpressionBody : CustomStringConvertible {
    var unit: ExpressionUnit!
    var left: ExpressionUnit! {
        get { return unit }
        set(l) { unit = l }
    }
    var cond: ExpressionUnit! {
        get { return unit }
        set(c) { unit = c }
    }

    public var description: String { get {
        return "(ExpressionBody \(unit))"
    } }
}

public class BinaryExpressionBody : ExpressionBody {
    var op: OperatorRef!
    var right: ExpressionBody!

    override public var description: String { get {
        return "(BinaryExpressionBody \(left) \(op) \(right))"
    } }
}

public class ConditionalExpressionBody : ExpressionBody {
    var trueSide: Expression!
    var falseSide: Expression!

    override public var description: String { get {
        return "(ConditionalExpressionBody \(cond) \(trueSide) \(falseSide))"
    } }
}

public class TypeCastingExpressionBody : ExpressionBody {
    var castType: CastType!
    var type: Type!

    override public var description: String { get {
        return "(TypeCastingExpressionBody \(castType) \(type))"
    } }
}

public enum CastType {
    case Is, As, ConditionalAs, ForcedAs
}

// prefix-expression
public class ExpressionUnit {
    var pre: ExpressionPrefix!
    var core: ExpressionCore!
    var posts: [ExpressionPostfix] = []
}

public enum ExpressionPrefix {
    case Nothing
    case Operator(OperatorRef)
    case InOut
}

public enum ExpressionPostfix {
    case Initializer, PostfixSelf, DynamicType
    case ForcedValue, OptionalChaining
    case Operator(OperatorRef)
    case ExplicitNamedMember(MemberRef, genArgs: [Type]?)
    case ExplicitUnnamedMember(MemberRef)
    case Subscript([Expression])
    case FunctionCall(Tuple)
}

// primary-expression
public enum ExpressionCore {
    case Value(ValueInst, genArgs: [Type]?)
    case BindingValue(ValueInst)
    case Integer(Int64)
    case FloatingPoint(Double)
    case StringExpression(String)
    case Boolean(Bool)
    case Nil
    case Array([Expression])
    case Dictionary([(Expression, Expression)])
    case SelfExpression, SelfInitializer
    case SelfMember(MemberRef)
    case SelfSubscript([Expression])
    case SuperClassInitializer
    case SuperClassMember(MemberRef)
    case SuperClassSubscript([Expression])
    case ClosureExpression(Closure)
    case TupleExpression(Tuple)
    case ImplicitMember(MemberRef)
    case Wildcard
}

public class Closure {
    var caps: [(CaptureSpecifier, Expression)] = []
    var params: ClosureParameters!
    var returns: ([Attribute], Type)?
    var body: [Procedure]!
}

public enum CaptureSpecifier {
    case Nothing, Weak, Unowned, UnownedSafe, UnownedUnsafe
}

public enum ClosureParameters {
    case NotProvided
    case ExplicitTyped(ParameterClause)
    case ImplicitTyped([ValueInst])
}

public typealias Tuple = [(String?, Expression)]
