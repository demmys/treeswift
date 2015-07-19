/*
 * expression
 */
public class Expression {
    var tryType: TryType!
    let body: ExpressionBody
}

public enum TryType {
    case Nothing, Try, ForcedTry
}

public class ExpressionBody {
    var unit: ExpressionUnit!
    var left: ExpressionUnit! {
        get { return unit }
        set(l) { unit = l }
    }
    var cond: ExpressionUnit! {
        get { return unit }
        set(c) { unit = c }
    }
}

public class BinaryExpressionBody : ExpressionBody {
    var op: OperatorRef! // TODO
    var right: ExpressionBody!
}

public class ConditionalExpressionBody : ExpressionBody {
    let trueSide: Expression
    let falseSide: Expression

    init(cond: ExpressionUnit, trueSide: Expression, falseSide: Expression) {
        self.trueSide = trueSide
        self.falseSide = falseSide
        super.init(unit: cond)
    }
}

public class TypeCastingExpressionBody : ExpressionBody {
    var castType: CastType!
    var type: TypeRef! // TODO
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
    case Initializer, Self, DynamicType
    case ForcedValue, OptionalChaining
    case Operator(OperatorRef)
    case ExplicitNamedMember(MemberRef, genericArguments: [TypeRef]?) // TODO
    case ExplicitUnnamedMember(MemberRef) // TODO
    case Subscript([Expression])
    case FunctionCall(Tuple) // TODO
}

// primary-expression
public enum ExpressionCore {
    case ValueRef(ValueRef, genericArguments: [TypeRef]?) // TODO
    case FunctionRef(FunctionRef) // TODO
    case Integer(Int64)
    case FloatingPoint(Double)
    case String(String)
    case Boolean(Bool)
    case Nil
    case Array([Expression])
    case Dictionary([(Expression, Expression)])
    case Self, SelfInitializer
    case SelfMember(MemberRef)
    case SelfSubscript([Expression])
    case SuperClassInitializer
    case SuperClassMember(MemberRef)
    case SuperClassSubscript([Expression])
    case Closure // TODO
    case Tuple(Tuple) // TODO
    case ImplicitMember(MemberRef)
    case Wildcard
}

typealias Tuple = [(String?, Expression)]