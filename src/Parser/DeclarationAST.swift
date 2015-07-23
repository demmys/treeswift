public protocol Declaration : CustomStringConvertible {}

public enum VariableDeclaration : Declaration {
    case PatternInitializerList([(Pattern, Expression?)])
}
