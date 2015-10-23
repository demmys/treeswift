import Util

public class Declaration : CustomStringConvertible {
    var attrs: [Attribute] = []
    var mods: [Modifier] = []

    init() {}
    private init(_ attrs: [Attribute], _ mods: [Modifier]) {
        self.attrs = attrs
        self.mods = mods
    }
    private init(_ attrs: [Attribute], _ mod: Modifier?) {
        self.attrs = attrs
        if let m = mod {
            self.mods = [m]
        }
    }
    private init(_ attrs: [Attribute]) {
        self.attrs = attrs
    }
    private init(_ mod: Modifier?) {
        if let m = mod {
            self.mods = [m]
        }
    }

    public var description: String {
        return "<<error: no description provided>>"
    }
}

public class TypeInheritanceClause {
    var classRequirement = false
    var types: [IdentifierType] = []

    init() {}
}

public class ImportDeclaration : Declaration {
    var kind: ImportKind?
    var path: [String] = []

    override init(_ attrs: [Attribute]) {
        super.init(attrs)
    }

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

    init(
        _ attrs: [Attribute], _ mods: [Modifier],
        isVariable: Bool, inits: [(Pattern, Expression?)]
    ) {
        super.init(attrs, mods)
        self.isVariable = isVariable
        self.inits = inits
    }

    public override var description: String {
        return "(PatternInitializerDeclaration variable: \(isVariable) \(attrs) \(mods) \(inits))"
    }
}

public class VariableBlockDeclaration : Declaration {
    var name: ValueInst!
    var specifier: VariableBlockSpecifier!
    var blocks: VariableBlocks!

    init(_ attrs: [Attribute], _ mods: [Modifier], name: ValueInst) {
        super.init(attrs, mods)
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
    var param: ValueInst?
    var body: [Procedure]!

    init() {}
    init(_ attrs: [Attribute]) {
        self.attrs = attrs
    }
}

public class TypealiasDeclaration : Declaration {
    var name: TypeRef!
    var inherits: TypeInheritanceClause?
    var type: Type?

    override init(_ attrs: [Attribute], _ mod: Modifier?) {
        super.init(attrs, mod)
    }

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

    override init(_ attrs: [Attribute], _ mods: [Modifier]) {
        super.init(attrs, mods)
    }

    public override var description: String {
        return "(FunctionDeclaration \(attrs) \(mods) \(throwType) \(name) \(genParam) \(params) \(returns) \(body))"
    }
}

public enum FunctionReference {
    case Function(ValueInst)
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
    case Specified(String, SourceInfo)
    case SpecifiedInst(ValueInst)
    case Needless
}

public class EnumDeclaration : Declaration {
    var isIndirect: Bool
    var isRawValueStyle = false
    var name: EnumRef!
    var genParam: GenericParameterClause?
    var inherits: TypeInheritanceClause?
    var members: [EnumMember]!

    init(_ attrs: [Attribute], _ mod: Modifier?, isIndirect: Bool) {
        self.isIndirect = isIndirect
        super.init(attrs, mod)
    }

    public override var description: String {
        return "(EnumDeclaration raw-value-style: \(isRawValueStyle) indirect: \(isIndirect) \(attrs) \(mods) \(name) \(genParam) \(inherits) \(members))"
    }
}

public enum EnumMember {
    case DeclarationMember(Declaration)
    case AlterableStyleMember(EnumCaseClause)
    case UnionStyleMember(isIndirect: Bool, EnumCaseClause)
    case RawValueStyleMember(EnumCaseClause)
}

public class EnumCaseClause {
    var attrs: [Attribute]
    var cases: [EnumCase] = []

    init(_ attrs: [Attribute]) {
        self.attrs = attrs
    }
}

public class EnumCase : CustomStringConvertible {
    var name: EnumCaseRef!

    init(_ name: EnumCaseRef) {
        self.name = name
    }

    public var description: String {
        return "(EnumCase \(name))"
    }
}

public class UnionStyleEnumCase : EnumCase {
    var tuple: TupleType!

    init(_ name: EnumCaseRef, _ tuple: TupleType) {
        super.init(name)
        self.tuple = tuple
    }

    public override var description: String {
        return "(UnionStyleEnumCase \(name) \(tuple))"
    }
}

public class RawValueStyleEnumCase : EnumCase {
    var value: RawValueLiteral!

    init(_ name: EnumCaseRef, _ value: RawValueLiteral) {
        super.init(name)
        self.value = value
    }

    public override var description: String {
        return "(RawValueStyleEnumCase \(name) \(value))"
    }
}

public enum RawValueLiteral {
    case IntegerLiteral(Int64)
    case FloatingPointLiteral(Double)
    case StringLiteral(String)
}

public class StructDeclaration : Declaration {
    var name: StructRef!
    var genParam: GenericParameterClause?
    var inherits: TypeInheritanceClause?
    var body: [Declaration] = []

    override init(_ attrs: [Attribute], _ mod: Modifier?) {
        super.init(attrs, mod)
    }

    public override var description: String {
        return "(StructDeclaration \(name) \(genParam) \(inherits) \(body))"
    }
}

public class ClassDeclaration : Declaration {
    var name: ClassRef!
    var genParam: GenericParameterClause?
    var inherits: TypeInheritanceClause?
    var body: [Declaration] = []

    override init(_ attrs: [Attribute], _ mod: Modifier?) {
        super.init(attrs, mod)
    }

    public override var description: String {
        return "(ClassDeclaration \(name) \(genParam) \(inherits) \(body)"
    }
}

public class ProtocolDeclaration : Declaration {
    var name: ProtocolRef!
    var inherits: TypeInheritanceClause?
    var body: [Declaration] = []

    override init(_ attrs: [Attribute], _ mod: Modifier?) {
        super.init(attrs, mod)
    }

    public override var description: String {
        return "(ProtocolDeclaration \(name) \(inherits) \(body))"
    }
}

public class InitializerDeclaration : Declaration {
    var failable: FailableType!
    var genParam: GenericParameterClause?
    var params: ParameterClause!
    var body: [Procedure] = []

    override init(_ attrs: [Attribute], _ mods: [Modifier]) {
        super.init(attrs, mods)
    }

    public override var description: String {
        return "(InitializerDeclaration \(failable) \(genParam) \(params) \(body))"
    }
}

public enum FailableType : String {
    case Nothing, Failable, ForceUnwrapFailable
}

public class DeinitializerDeclaration : Declaration {
    let body: [Procedure]

    init(_ attrs: [Attribute], _ body: [Procedure]) {
        self.body = body
        super.init(attrs)
    }

    public override var description: String {
        return "(DeinitializerDeclaration \(body))"
    }
}

public class ExtensionDeclaration : Declaration {
    var type: IdentifierType!
    var inherits: TypeInheritanceClause?
    var body: [Declaration] = []

    override init(_ mod: Modifier?) {
        super.init(mod)
    }

    public override var description: String {
        return "(ExtensionDeclaration \(type) \(inherits) \(body))"
    }
}

public class SubscriptDeclaration : Declaration {
    var params: ParameterClause!
    var returns: ([Attribute], Type)!
    var body: VariableBlocks!

    override init(_ attrs: [Attribute], _ mods: [Modifier]) {
        super.init(attrs, mods)
    }

    public override var description: String {
        return "(SubscriptDeclaration \(params) \(returns) \(body))"
    }
}

public class OperatorDeclaration : Declaration {
    let kind: OperatorDeclarationKind
    let name: OperatorRef

    public init(_ kind: OperatorDeclarationKind, _ name: OperatorRef!) {
        self.kind = kind
        self.name = name
        super.init()
    }

    public override var description: String {
        return "(OperatorDeclaration \(kind) \(name))"
    }
}
public enum OperatorDeclarationKind {
    case Prefix, Postfix
    case Infix(precedence: Int64, associativity: Associativity)
}

public enum Associativity : String {
    case Left, Right, None
}
