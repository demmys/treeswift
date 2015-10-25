public class Expression {
    public var tryType: TryType!
    public var body: ExpressionBody!

    public init() {}
}

public enum TryType : String {
    case Nothing, Try, ForcedTry
}

public class ExpressionBody : CustomStringConvertible {
    public var unit: ExpressionUnit!
    public var left: ExpressionUnit! {
        get { return unit }
        set(l) { unit = l }
    }
    public var cond: ExpressionUnit! {
        get { return unit }
        set(c) { unit = c }
    }

    public init() {}

    public var description: String { get {
        return "(ExpressionBody \(unit))"
    } }
}

public class BinaryExpressionBody : ExpressionBody {
    public var op: OperatorRef!
    public var right: ExpressionBody!

    public override init() {}

    public override var description: String { get {
        return "(BinaryExpressionBody \(left) \(op) \(right))"
    } }
}

public class ConditionalExpressionBody : ExpressionBody {
    public var trueSide: Expression!
    public var falseSide: Expression!

    public override init() {}

    public override var description: String { get {
        return "(ConditionalExpressionBody \(cond) \(trueSide) \(falseSide))"
    } }
}

public class TypeCastingExpressionBody : ExpressionBody {
    public var castType: CastType!
    public var type: Type!

    public override init() {}

    public override var description: String { get {
        return "(TypeCastingExpressionBody \(castType) \(type))"
    } }
}

public enum CastType {
    case Is, As, ConditionalAs, ForcedAs
}

// prefix-expression
public class ExpressionUnit {
    public var pre: ExpressionPrefix!
    public var core: ExpressionCore!
    public var posts: [ExpressionPostfix] = []

    public init() {}
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
    case Value(UnresolvedValueRef, genArgs: [Type]?)
    case BindingValue(UnresolvedValueRef)
    case ImplicitParameter(UnresolvedImplicitParameterRef, genArgs: [Type]?)
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

public class Closure : ScopeTrackable {
    public var caps: [(CaptureSpecifier, Expression)] = []
    public var params: ClosureParameters!
    public var returns: ([Attribute], Type)?
    public var body: [Procedure]!
    public var associatedScope: Scope!

    public init() {}

    public var scope: Scope { return associatedScope }
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
