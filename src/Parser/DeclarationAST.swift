public class Declaration : CustomStringConvertible {
    var attrs: [Attribute] = []
    var mods: [Modifier] = []

    public var description: String {
        return "<<error: no description provided>>"
    }
}

public class ImportDeclaration : Declaration {
    var kind: ImportKind!
    var path: [Identifier]

    init() {}

    public override var description: String {
        return "(ImportDeclaration kind: \(attrs) \(kind) \(path))"
    }
}

public enum ImportKind : String {
    case Typealias, Struct, Class, Enum, Protocol, Var, Func
}

public class PatternInitializerDeclaration : Declaration {
    var isVariable = false
    var inits: [(Pattern, Expression?)] = []

    init() {}

    public override var description: String {
        return "(PatternInitializerDeclaration variable: \(isVariable) \(attrs) \(mods) \(inits))"
    }
}

public class VariableBlockDeclaration : Declaration {
    var name: ValueRef!
    var block: [VariableBlock] = []

    init() {}

    public override var description: String {
        return "(VariableBlockDeclaration \(attrs) \(mods) \(name) \(block))"
    }
}

public enum VariableBlock {
    case Getter(Type, [Attribute], [Procedure])
    case Setter(Type, [Attribute], ValueRef?, [Procedure])
    case GetterKeyword(Type, [Attribute])
    case SetterKeyword(Type, [Attribute])
    case WillSet(VariableBlockSpecifier, [Attribute], ValueRef?, [Procedure])
    case DidSet(VariableBlockSpecifier, [Attribute], ValueRef?, [Procedure])
}

public enum VariableBlockSpecifier {
    case Initializer(Expression)
    case TypeAnnotation(Type)
    case TypedInitializer(Type, Expression)
}

public class TypealiasDeclaration : Declaration {
    var name: TypeRef!
    var type: Type!

    init() {}

    public override var description: String {
        return "(TypealiasDeclaration \(attrs) \(mods) \(name) \(type))"
    }
}

public class FunctionDeclaration : Declaration {
    var name: FunctionReference!
    var genParam: GenericParameterClause? // TODO
    var params: [ParameterClause]!
    var throwType: ThrowType!
    var returns: ([Attribute], Type)?
    var body: [Procedure]!

    init() {}

    public override var description: String {
        return "(FunctionDeclaration \(throwType) \(name) \(genParam) \(params) \(returns) \(body))"
    }
}

public enum FunctionReference {
    case Function(ValueRef)
    case Operator(OperatorRef)
}

public enum ThrowType : String {
    case Nothing, Throws, Rethrows
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

// TODO enum

// TODO struct

// TODO class

// TODO protocol

// TODO initializer

// TODO deinializer

// TODO extension

// TODO subscript

// TODO operator
