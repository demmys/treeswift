public class Pattern : Typeable, CustomStringConvertible {
    public var type = TypeManager()

    public init() {}

    public var description: String {
        return "<<error: no description provided>>"
    }
}

public class IdentityPattern : Pattern {
    override public var description: String {
        return "(Pattern type: identity \(type))"
    }
}

public class BooleanPattern : Pattern {
    override public var description: String {
        return "(Pattern type: boolean \(type))"
    }
}

public class ConstantIdentifierPattern : Pattern {
    public let inst: ConstantInst

    public init(_ inst: ConstantInst) {
        self.inst = inst
    }

    override public var description: String {
        return "(Pattern type: constant-identifier \(inst) \(type))"
    }
}

public class VariableIdentifierPattern : Pattern {
    public let inst: VariableInst

    public init(_ inst: VariableInst) {
        self.inst = inst
    }

    override public var description: String {
        return "(Pattern type: variable-identifier \(inst) \(type))"
    }
}

public class ReferenceIdentifierPattern : Pattern {
    public let ref: ValueRef

    public init(_ ref: ValueRef) {
        self.ref = ref
    }

    override public var description: String {
        return "(Pattern type: reference-identifier \(ref) \(type))"
    }
}

public class WildcardPattern : Pattern {
    override public var description: String {
        return "(Pattern wildcard-pattern \(type))"
    }
}

public typealias PatternTuple = [(String?, Pattern)]

public class TuplePattern : Pattern {
    public let tuple: PatternTuple

    public init(_ tuple: PatternTuple) {
        self.tuple = tuple
    }

    override public var description: String {
        return "(Pattern type: tuple \(tuple) \(type))"
    }
}

public class ContainerPattern : Pattern {
    public let pat: Pattern

    public init(_ pat: Pattern) {
        self.pat = pat
    }
}

public class VariableBindingPattern : ContainerPattern {
    override public var description: String {
        return "(Pattern type: variable-binding \(pat) \(type))"
    }
}

public class ConstantBindingPattern : ContainerPattern {
    override public var description: String {
        return "(Pattern type: constant-binding \(pat) \(type))"
    }
}

public class EnumCasePattern : Pattern {
    public let ref: EnumCaseRef
    public let tuple: PatternTuple

    public init(_ ref: EnumCaseRef, _ tuple: PatternTuple) {
        self.ref = ref
        self.tuple = tuple
    }

    override public var description: String {
        return "(Pattern type: enum-case \(ref) \(tuple) \(type))"
    }
}

public class TypePattern : Pattern {
    public let targetType: Type

    public init(_ targetType: Type) {
        self.targetType = targetType
        super.init()
        type.fixType(targetType)
    }

    override public var description: String {
        return "(Pattern type: type \(targetType))"
    }
}

public class ExpressionPattern : Pattern {
    public let exp: Expression

    public init(_ exp: Expression) {
        self.exp = exp
    }

    override public var description: String {
        return "(Pattern type: expression \(exp) \(type))"
    }
}

public class OptionalPattern : ContainerPattern {
    override public var description: String {
        return "(Pattern type: optional \(pat) \(type))"
    }
}

public class TypeCastingPattern : ContainerPattern {
    public var castType: Type

    public init(_ pat: Pattern, _ castType: Type) {
        self.castType = castType
        super.init(pat)
        type.fixType(castType)
    }

    override public var description: String {
        return "(Pattern type: typeCasting \(pat) \(castType))"
    }
}
