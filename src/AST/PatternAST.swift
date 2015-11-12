public class Pattern : Typeable, CustomStringConvertible {
    private var _type: Type?
    public var type: Type? {
        get { return _type }
        set (t) { _type = t }
    }

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
    override public var type: Type? {
        get { return _type }
        set {}
    }

    public init(_ type: Type?) {
        super.init()
        _type = type
    }

    override public var description: String {
        return "(Pattern type: type \(type))"
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
    override public var type: Type? {
        get { return _type }
        set {}
    }

    public init(_ pat: Pattern, _ type: Type?) {
        super.init(pat)
        _type = type
    }

    override public var description: String {
        return "(Pattern type: typeCasting \(pat) \(type) \(type))"
    }
}

/*
public indirect enum Pattern : Typeable {
    case IdentityPattern(Type?)
    case BooleanPattern(Type?)
    case ConstantIdentifierPattern(ConstantInst, Type?)
    case VariableIdentifierPattern(VariableInst, Type?)
    case ReferenceIdentifierPattern(ValueRef, Type?)
    case WildcardPattern(Type?)
    case TuplePattern(PatternTuple, Type?)
    case VariableBindingPattern(Pattern, Type?)
    case ConstantBindingPattern(Pattern, Type?)
    case EnumCasePattern(EnumCaseRef, PatternTuple, Type?)
    case TypePattern(Type)
    case ExpressionPattern(Expression, Type?)
    case OptionalPattern(Pattern, Type?)
    case TypeCastingPattern(Pattern, Type)

    public var type: Type? {
        get {
            switch self {
            case let .IdentityPattern(t): return t
            case let .BooleanPattern(t): return t
            case let .ConstantIdentifierPattern(_, t): return t
            case let .VariableIdentifierPattern(_, t): return t
            case let .ReferenceIdentifierPattern(_, t): return t
            case let .WildcardPattern(t): return t
            case let .TuplePattern(_, t): return t
            case let .VariableBindingPattern(_, t): return t
            case let .ConstantBindingPattern(_, t): return t
            case let .EnumCasePattern(_, _, t): return t
            case let .TypePattern(t): return t
            case let .ExpressionPattern(_, t): return t
            case let .OptionalPattern(_, t): return t
            case let .TypeCastingPattern(_, t): return t
            }
        }

        set (t) {
            switch self {
            case .IdentityPattern:
                self = .IdentityPattern(t)
            case .BooleanPattern:
                self = .BooleanPattern(t)
            case let .ConstantIdentifierPattern(i, _):
                self = .ConstantIdentifierPattern(i, t)
            case let .VariableIdentifierPattern(i, _):
                self = .VariableIdentifierPattern(i, t)
            case .ReferenceIdentifierPattern(i, _):
                self = .ReferenceIdentifierPattern(i, t)
            case .WildcardPattern:
                self = .WildcardPattern(t)
            case let .TuplePattern(p):
                self = .TuplePattern(p, t)
            case let .VariableBindingPattern(p, _):
                self = .VariableBindingPattern(p, t)
            case let .ConstantBindingPattern(p):
                self = .ConstantBindingPattern(t)
            case let .EnumCasePattern(r, p, _):
                self = .EnumCasePattern(r, p, t)
            case .TypePattern:
                break
            case let .ExpressionPattern(e, _):
                self = .ExpressionPattern(e, t)
            case let .OptionalPattern(p, _):
                self = .OptionalPattern(p, t)
            case .TypeCastingPattern:
                break
            }
        }
    }
}
*/
