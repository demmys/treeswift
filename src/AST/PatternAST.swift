public indirect enum Pattern {
    case IdentityPattern
    case BooleanPattern
    case OptionalBindingConstantPattern(Pattern)
    case OptionalBindingVariablePattern(Pattern)
    case IdentifierPattern(ValueInst)
    case TypedIdentifierPattern(ValueInst, Type, [Attribute])
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
