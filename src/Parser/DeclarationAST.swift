public class Declaration : CustomStringConvertible {
    var attrs: [Attribute] = []
    var mods: [Modifier] = []

    public var description: String {
        return "<<error: no description provided>>"
    }
}

public class ImportDeclaration : Declaration {
    var kind: ImportKind!
    var path: [String] = []

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

    init(isVariable: Bool) {
        self.isVariable = isVariable
    }
    init(isVariable: Bool, inits: [(Pattern, Expression?)]) {
        self.isVariable = isVariable
        self.inits = inits
    }

    public override var description: String {
        return "(PatternInitializerDeclaration variable: \(isVariable) \(attrs) \(mods) \(inits))"
    }
}

public class VariableBlockDeclaration : Declaration {
    var name: ValueRef!
    var specifier: VariableBlockSpecifier!
    var blocks: VariableBlocks!

    init(_ name: ValueRef) {
        self.name = name
    }

    public override var description: String {
        return "(VariableBlockDeclaration \(attrs) \(mods) \(name) \(specifier) \(blocks))"
    }
}

public enum VariableBlockSpecifier {
    case Initializer(Expression)
    case TypeAnnotation(Type, [Attribute])
    case TypedInitializer(Type, [Attribute], Expression)
}

public enum VariableBlocks {
    case GetterSetter(getter: VariableBlock, setter: VariableBlock?)
    case GetterKeyword([Attribute])
    case GetterSetterKeyword(getAttrs: [Attribute], setAttrs: [Attribute])
    case WillSetDidSet(willSetter: VariableBlock?, didSetter: VariableBlock?)
}

public class VariableBlock {
    var attrs: [Attribute] = []
    var param: ValueRef?
    var body: [Procedure]!

    init() {}
}

public class TypealiasDeclaration : Declaration {
    var name: TypeRef!
    var inherits: [IdentifierType] = []
    var type: Type?

    public override var description: String {
        return "(TypealiasDeclaration \(attrs) \(mods) \(name) \(type))"
    }
}

public class FunctionDeclaration : Declaration {
    var name: FunctionReference!
    var genParam: GenericParameterClause?
    var params: [ParameterClause]!
    var throwType: ThrowType!
    var returns: ([Attribute], Type)?
    var body: [Procedure] = []

    public override var description: String {
        return "(FunctionDeclaration \(attrs) \(mods) \(throwType) \(name) \(genParam) \(params) \(returns) \(body))"
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

public class EnumDeclaration : Declaration {
    var isRawValueStyle = false
    var isIndirect = false
    var name: EnumRef!
    var genParam: GenericParameterClause?
    var inherits: [IdentifierType] = []
    var decs: [Declaration] = []
    var caseClause: EnumCaseClause!

    public override var description: String {
        return "(EnumDeclaration raw-value-style: \(isRawValueStyle) indirect: \(isIndirect) \(attrs) \(mods) \(name) \(genParam) \(inherits) \(decs) \(caseClause))"
    }
}

public enum EnumCaseClause {
    case UnionStyle([UnionStyleEnumCaseClause])
    case RawValueStyle([RawValueStyleEnumCaseClause])
}

public class UnionStyleEnumCaseClause {
    var attrs: [Attribute] = []
    var isIndirect = false
    var cases: [UnionStyleEnumCase] = []

    init() {}
}

public class UnionStyleEnumCase {
    var name: EnumCaseRef!
    var tuple: TupleType?

    init() {}
}

public class RawValueStyleEnumCaseClause {
    var attrs: [Attribute] = []
    var cases: [RawValueStyleEnumCase] = []

    init() {}
}

public class RawValueStyleEnumCase {
    var name: EnumCaseRef!
    var value: RawValueLiteral?

    init() {}
}

public enum RawValueLiteral {
    case NumericLiteral(Int)
    case StringLiteral(String)
}

public class StructDeclaration : Declaration {
    var name: StructRef!
    var genParam: GenericParameterClause?
    var inherits: [IdentifierType] = []
    var body: [Declaration] = []

    public override var description: String {
        return "(StructDeclaration \(name) \(genParam) \(inherits) \(body))"
    }
}

public class ClassDeclaration : Declaration {
    var name: ClassRef!
    var genParam: GenericParameterClause?
    var inherits: [IdentifierType] = []
    var body: [Declaration] = []

    public override var description: String {
        return "(ClassDeclaration \(name) \(genParam) \(inherits) \(body)"
    }
}

public class ProtocolDeclaration : Declaration {
    var name: ProtocolRef!
    var inherits: [IdentifierType] = []
    var body: [Declaration] = []

    public override var description: String {
        return "(ProtocolDeclaration \(name) \(inherits) \(body))"
    }
}

public class InitializerDeclaration : Declaration {
    var failable: FailableType!
    var genParam: GenericParameterClause?
    var params: [ParameterClause]!
    var body: [Procedure] = []

    public override var description: String {
        return "(InitializerDeclaration \(failable) \(genParam) \(params) \(body))"
    }
}

public enum FailableType : String {
    case Nothing, Failable, ForceUnwrapFailable
}

public class DeinitializerDeclaration : Declaration {
    var body: [Procedure] = []

    public override var description: String {
        return "(DeinitializerDeclaration \(body))"
    }
}

public class ExtensionDeclaration : Declaration {
    var type: IdentifierType!
    var inherits: [IdentifierType] = []
    var body: [Declaration] = []

    public override var description: String {
        return "(ExtensionDeclaration \(type) \(inherits) \(body))"
    }
}

public class SubscriptDeclaration : Declaration {
    var params: [ParameterClause]!
    var returns: ([Attribute], Type)?
    var body: VariableBlocks!

    public override var description: String {
        return "(SubscriptDeclaration \(params) \(returns) \(body))"
    }
}

public class OperatorDeclaration : Declaration {
    var kind: OperatorDeclarationKind!

    public override var description: String {
        return "(OperatorDeclaration \(kind))"
    }
}
public enum OperatorDeclarationKind {
    case Prefix, Postfix
    case Infix(precedence: Int, associativity: Associativity)
}

public enum Associativity : String {
    case Left, Right, None
}
