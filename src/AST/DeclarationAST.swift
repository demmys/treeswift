public class Module : ScopeTrackable {
    public let declarations: [Declaration]
    public let moduleScope: Scope

    public init(declarations: [Declaration], moduleScope: Scope) {
        self.declarations = declarations
        self.moduleScope = moduleScope
    }

    public var scope: Scope { return moduleScope }
}

public class TopLevelDeclaration : ScopeTrackable {
    public let procedures: [Procedure]
    public let fileScope: Scope
    public var isMain = false

    public init(procedures: [Procedure], fileScope: Scope) {
        self.procedures = procedures
        self.fileScope = fileScope
    }

    public var scope: Scope { return fileScope }
}

public class Declaration {
    public var attrs: [Attribute] = []
    public var al: AccessLevel?
    public var mods: [Modifier] = []

    public init() {}
    private init(_ attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]) {
        self.attrs = attrs
        self.al = al
        self.mods = mods
    }
    private init(_ attrs: [Attribute], _ al: AccessLevel?) {
        self.attrs = attrs
        self.al = al
    }
    private init(_ attrs: [Attribute]) {
        self.attrs = attrs
    }
    private init(_ al: AccessLevel?) {
        self.al = al
    }
}

public class TypeInheritanceClause {
    public var classRequirement = false
    public var types: [IdentifierType] = []

    public init() {}
}

public class ImportDeclaration : Declaration, SourceTrackable {
    public var kind: ImportKind?
    public var name: String = ""
    private let info: SourceInfo

    public init(_ attrs: [Attribute], _ source: SourceTrackable) {
        self.info = source.sourceInfo
        super.init(attrs)
    }

    public var sourceInfo: SourceInfo {
        return info
    }
}

public enum ImportKind : String {
    case Typealias, Struct, Class, Enum, Protocol, Var, Func
}

public typealias PatternInitializer = (Pattern, TypeAnnotation?, Expression?)

public class PatternInitializerDeclaration : Declaration {
    public var inits: [PatternInitializer] = []

    public init(
        _ attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier],
        inits: [PatternInitializer]
    ) {
        super.init(attrs, al, mods)
        self.inits = inits
    }
}

public class VariableBlockDeclaration : Declaration {
    public var name: VariableInst!
    public var annotation: TypeAnnotation?
    public var initializer: Expression?
    public var blocks: VariableBlocks!

    public init(
        _ attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier], name: VariableInst
    ) {
        super.init(attrs, al, mods)
        self.name = name
    }
}

public enum VariableBlocks {
    case GetterSetter(getter: VariableBlock, setter: VariableBlock?)
    case GetterKeyword([Attribute])
    case GetterSetterKeyword(getAttrs: [Attribute], setAttrs: [Attribute])
    case WillSetDidSet(willSetter: VariableBlock?, didSetter: VariableBlock?)
}

public class VariableBlock : ScopeTrackable, Typeable {
    public var type = TypeManager()
    public var attrs: [Attribute] = []
    public var param: ConstantInst?
    public var body: [Procedure]!
    public var associatedScope: Scope!

    public init() {}
    public init(_ attrs: [Attribute]) {
        self.attrs = attrs
    }

    public var scope: Scope { return associatedScope }
}

public class TypealiasDeclaration : Declaration {
    public var name: TypeInst!
    public var inherits: TypeInheritanceClause?
    public var aliasedType: Type?

    public override init(_ attrs: [Attribute], _ al: AccessLevel?) {
        super.init(attrs, al)
    }
}

public class FunctionDeclaration : Declaration, ScopeTrackable {
    public var name: FunctionReference!
    public var genParam: GenericParameterClause?
    public var params: [[Parameter]]!
    public var throwType: ThrowType!
    public var returns: ([Attribute], Type)?
    public var body: [Procedure] = []
    public var associatedScope: Scope!

    public override init(_ attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]) {
        super.init(attrs, al, mods)
    }

    public var scope: Scope { return associatedScope }
}

public enum FunctionReference {
    case Function(FunctionInst)
    case Operator(OperatorRef, FunctionInst)
}

public enum ThrowType : String {
    case Nothing, Throws, Rethrows
}

public enum ParameterKind {
    case Constant, Variable, InOut, Variadic, None
}

public class Parameter {
    public var kind = ParameterKind.None
    public var externalName: ParameterName!
    public var internalName: ParameterName!
    public var type: TypeAnnotation!
    public var defaultArg: Expression?

    public init() {}
}

public enum ParameterName {
    case NotSpecified
    case Specified(String, SourceInfo)
    case SpecifiedConstantInst(ConstantInst)
    case SpecifiedVariableInst(VariableInst)
    case Needless
}

public class EnumDeclaration : Declaration, ScopeTrackable {
    public var isIndirect: Bool
    public var isRawValueStyle = false
    public var name: EnumInst!
    public var genParam: GenericParameterClause?
    public var inherits: TypeInheritanceClause?
    public var members: [EnumMember]!
    public var associatedScope: Scope!

    public init(_ attrs: [Attribute], _ al: AccessLevel?, isIndirect: Bool) {
        self.isIndirect = isIndirect
        super.init(attrs, al)
    }

    public var scope: Scope { return associatedScope }
}

public enum EnumMember {
    case DeclarationMember(Declaration)
    case AlterableStyleMember(EnumCaseClause)
    case UnionStyleMember(isIndirect: Bool, EnumCaseClause)
    case RawValueStyleMember(EnumCaseClause)
}

public class EnumCaseClause {
    public var attrs: [Attribute]
    public var cases: [EnumCase] = []

    public init(_ attrs: [Attribute]) {
        self.attrs = attrs
    }
}

public class EnumCase : CustomStringConvertible {
    public var name: EnumCaseInst!

    public init(_ name: EnumCaseInst) {
        self.name = name
    }

    public var description: String {
        return "(EnumCase \(name))"
    }
}

public class UnionStyleEnumCase : EnumCase {
    public var tuple: TupleType!

    public init(_ name: EnumCaseInst, _ tuple: TupleType) {
        super.init(name)
        self.tuple = tuple
    }

    public override var description: String {
        return "(UnionStyleEnumCase \(name) \(tuple))"
    }
}

public class RawValueStyleEnumCase : EnumCase {
    public var value: RawValueLiteral!

    public init(_ name: EnumCaseInst, _ value: RawValueLiteral) {
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

public class StructDeclaration : Declaration, ScopeTrackable {
    public var name: StructInst!
    public var genParam: GenericParameterClause?
    public var inherits: TypeInheritanceClause?
    public var body: [Declaration] = []
    public var associatedScope: Scope!

    public override init(_ attrs: [Attribute], _ al: AccessLevel?) {
        super.init(attrs, al)
    }

    public var scope: Scope { return associatedScope }
}

public class ClassDeclaration : Declaration, ScopeTrackable {
    public var name: ClassInst!
    public var genParam: GenericParameterClause?
    public var inherits: TypeInheritanceClause?
    public var body: [Declaration] = []
    public var associatedScope: Scope!

    public override init(_ attrs: [Attribute], _ al: AccessLevel?) {
        super.init(attrs, al)
    }

    public var scope: Scope { return associatedScope }
}

public class ProtocolDeclaration : Declaration, ScopeTrackable {
    public var name: ProtocolInst!
    public var inherits: TypeInheritanceClause?
    public var body: [Declaration] = []
    public var associatedScope: Scope!

    public override init(_ attrs: [Attribute], _ al: AccessLevel?) {
        super.init(attrs, al)
    }

    public var scope: Scope { return associatedScope }
}

public class InitializerDeclaration : Declaration, ScopeTrackable {
    public var failable: FailableType!
    public var genParam: GenericParameterClause?
    public var params: [Parameter]!
    public var body: [Procedure] = []
    public var associatedScope: Scope!

    public override init(_ attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]) {
        super.init(attrs, al, mods)
    }

    public var scope: Scope { return associatedScope }
}

public enum FailableType : String {
    case Nothing, Failable, ForceUnwrapFailable
}

public class DeinitializerDeclaration : Declaration, ScopeTrackable {
    public let body: [Procedure]
    public var associatedScope: Scope!

    public init(_ attrs: [Attribute], _ body: [Procedure]) {
        self.body = body
        super.init(attrs)
    }

    public var scope: Scope { return associatedScope }
}

public class ExtensionDeclaration : Declaration, ScopeTrackable {
    public var id: IdentifierType!
    public var inherits: TypeInheritanceClause?
    public var body: [Declaration] = []
    public var associatedScope: Scope!

    public override init(_ al: AccessLevel?) {
        super.init(al)
    }

    public var scope: Scope { return associatedScope }
}

public class SubscriptDeclaration : Declaration, ScopeTrackable {
    public var params: [Parameter]!
    public var returns: ([Attribute], Type)!
    public var body: VariableBlocks!
    public var associatedScope: Scope!

    public override init(_ attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]) {
        super.init(attrs, al, mods)
    }

    public var scope: Scope { return associatedScope }
}

public class OperatorDeclaration : Declaration {
    public let kind: OperatorDeclarationKind
    public let name: OperatorInst

    public init(_ kind: OperatorDeclarationKind, _ name: OperatorInst!) {
        self.kind = kind
        self.name = name
        super.init()
    }
}
public enum OperatorDeclarationKind {
    case Prefix, Postfix
    case Infix(precedence: Int64, associativity: Associativity)
}

public enum Associativity : String {
    case Left, Right, None
}
