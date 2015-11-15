public class Pattern : Typeable {
    public var type = TypeManager()

    public init() {}
}

public class IdentityPattern : Pattern {}

public class BooleanPattern : Pattern {}

public class ConstantIdentifierPattern : Pattern {
    public let inst: ConstantInst

    public init(_ inst: ConstantInst) {
        self.inst = inst
    }
}

public class VariableIdentifierPattern : Pattern {
    public let inst: VariableInst

    public init(_ inst: VariableInst) {
        self.inst = inst
    }
}

public class ReferenceIdentifierPattern : Pattern {
    public let ref: ValueRef

    public init(_ ref: ValueRef) {
        self.ref = ref
    }
}

public class WildcardPattern : Pattern {}

public typealias PatternTuple = [(String?, Pattern)]

public class TuplePattern : Pattern {
    public let tuple: PatternTuple

    public init(_ tuple: PatternTuple) {
        self.tuple = tuple
    }
}

public class ContainerPattern : Pattern {
    public let pat: Pattern

    public init(_ pat: Pattern) {
        self.pat = pat
    }
}

public class VariableBindingPattern : ContainerPattern {}

public class ConstantBindingPattern : ContainerPattern {}

public class EnumCasePattern : Pattern {
    public let ref: EnumCaseRef
    public let tuple: PatternTuple

    public init(_ ref: EnumCaseRef, _ tuple: PatternTuple) {
        self.ref = ref
        self.tuple = tuple
    }
}

public class TypePattern : Pattern {
    public let targetType: Type

    public init(_ targetType: Type) {
        self.targetType = targetType
        super.init()
        type.fixType(targetType)
    }
}

public class ExpressionPattern : Pattern {
    public let exp: Expression

    public init(_ exp: Expression) {
        self.exp = exp
    }
}

public class OptionalPattern : ContainerPattern {}

public class TypeCastingPattern : ContainerPattern {
    public var castType: Type

    public init(_ pat: Pattern, _ castType: Type) {
        self.castType = castType
        super.init(pat)
        type.fixType(castType)
    }
}
