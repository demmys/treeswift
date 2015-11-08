public indirect enum Pattern {
    case IdentityPattern
    case BooleanPattern
    case ConstantIdentifierPattern(ConstantInst)
    case VariableIdentifierPattern(VariableInst)
    case ReferenceIdentifierPattern(ValueRef)
    case TypedConstantIdentifierPattern(ConstantInst, Type, [Attribute])
    case TypedVariableIdentifierPattern(VariableInst, Type, [Attribute])
    case TypedReferenceIdentifierPattern(ValueRef, Type, [Attribute])
    case WildcardPattern
    case TypedWildcardPattern(Type, [Attribute]?)
    case TuplePattern(PatternTuple)
    case VariableBindingPattern(Pattern)
    case ConstantBindingPattern(Pattern)
    case EnumCasePattern(EnumCaseRef, PatternTuple)
    case TypePattern(Type)
    case ExpressionPattern(Expression)
    case OptionalPattern(Pattern)
    case TypeCastingPattern(Pattern, Type)
}

public typealias PatternTuple = [(String?, Pattern)]
