public class Expression : Typeable {
    public var type = TypeManager()
    public var tryType: TryType!
    public var body: ExpressionBody!

    public init() {}
}

public enum TryType : String {
    case Nothing, Try, ForcedTry
}

public class ExpressionBody : Typeable, CustomStringConvertible {
    public var type = TypeManager()
    public var unit: PrefixedExpression!
    public var left: PrefixedExpression! {
        get { return unit }
        set(l) { unit = l }
    }
    public var cond: PrefixedExpression! {
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
    public var dist: Type!

    public override init() {}

    public override var description: String { get {
        return "(TypeCastingExpressionBody \(castType) \(dist))"
    } }
}

public enum CastType : String {
    case Is, As, ConditionalAs, ForcedAs
}

public class PrefixedExpression : Typeable {
    public var type = TypeManager()
    public var pre: ExpressionPrefix
    public var core: PostfixedExpression

    public init(_ pre: ExpressionPrefix, _ core: PostfixedExpression) {
        self.pre = pre
        self.core = core
    }
}

public class PostfixedExpression : Typeable {
    public var type = TypeManager()
    public var core: PostfixedExpressionCore

    public init(_ core: PostfixedExpressionCore) {
        self.core = core
    }
}

public enum ExpressionPrefix {
    case Nothing
    case Operator(OperatorRef)
    case InOut
}

public enum PostfixedExpressionCore {
    case Core(ExpressionCore)
    case Operator(PostfixedExpression, OperatorRef)
    case FunctionCall(PostfixedExpression, Tuple)
    case Member(PostfixedExpression, PostfixMember)
    case Subscript(PostfixedExpression, [Expression])
    case ForcedValue(PostfixedExpression)
    case OptionalChaining(PostfixedExpression, PostfixMember)
}

public enum PostfixMember {
    case Initializer, PostfixSelf, DynamicType
    case ExplicitNamed(String, genArgs: [Type]?)
    case ExplicitUnnamed(Int64)
}

// primary-expression
public class ExpressionCore : Typeable {
    public var type = TypeManager()
    public let value: ExpressionCoreValue

    public init(_ v: ExpressionCoreValue) {
        value = v
    }
}

public enum ExpressionCoreValue {
    case Value(ValueRef, genArgs: [Type]?)
    case BindingConstant(ConstantInst)
    case BindingVariable(VariableInst)
    case ImplicitParameter(ImplicitParameterRef, genArgs: [Type]?)
    case Integer(Int64)
    case FloatingPoint(Double)
    case StringExpression(String)
    case Boolean(Bool)
    case Nil
    case Array([Expression])
    case Dictionary([(Expression, Expression)])
    case SelfExpression, SelfInitializer
    case SelfMember(String)
    case SelfSubscript([Expression])
    case SuperClassInitializer
    case SuperClassMember(String)
    case SuperClassSubscript([Expression])
    case ClosureExpression(Closure)
    case TupleExpression(Tuple)
    case ImplicitMember(String)
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
    case ExplicitTyped([Parameter])
    case ImplicitTyped([ConstantInst])
}

public typealias Tuple = [(String?, Expression)]
