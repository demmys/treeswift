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
    var op: OperatorRef!
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
    var type: Type!
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
    case ExplicitNamedMember(MemberRef, genArgs: [Type]?)
    case ExplicitUnnamedMember(MemberRef)
    case Subscript([Expression])
    case FunctionCall(Tuple)
}

// primary-expression
public enum ExpressionCore {
    case ValueRef(ValueRef, genArgs: [Type]?)
    case FunctionRef(FunctionRef)
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
    case Tuple(Tuple)
    case ImplicitMember(MemberRef)
    case Wildcard
}

typealias Tuple = [(String?, Expression)]
