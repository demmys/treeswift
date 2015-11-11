public indirect enum Pattern {
    case IdentityPattern
    case BooleanPattern
    case ConstantIdentifierPattern(ConstantInst)
    case VariableIdentifierPattern(VariableInst)
    case ReferenceIdentifierPattern(ValueRef)
    case WildcardPattern
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
