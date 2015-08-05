public protocol Declaration : CustomStringConvertible {}

public enum VariableDeclaration : Declaration {
    case PatternInitializerList([(Pattern, Expression?)])
}

public class ParameterClause {
    var body: [Parameter] = []
    var isVariadic = false

    init() {}
}

public enum Parameter {
    case Named(NamedParameter)
    case Unnamed([Attribute], Type)
}

public class NamedParameter {
    var isInout = false
    var isVariable = false
    var externalName: ParameterName!
    var internalName: ParameterName!
    var type: (Type, [Attribute])!
    var defaultArg: Expression?

    init() {}
}

public enum ParameterName {
    case NotSpecified
    case Specified(ValueRef)
    case Needless
}
