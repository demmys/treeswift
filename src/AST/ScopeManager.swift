public enum MemberPolicy {
    case Declarative, Procedural
}

public enum ScopeType {
    case Module, File
    case Implicit
    case For, ForIn, While, RepeatWhile, If, Guard, Defer, Do, Catch, Case
    case Function, Enum, Struct, Class, Protocol, Extension

    var policy: MemberPolicy {
        switch self {
        case .Module, .Enum, Struct, .Class, .Protocol, .Extension:
            return .Declarative
        case .Implicit, .File, .For, .ForIn, .While, .RepeatWhile, .If, .Guard,
             .Defer, .Do, .Catch, .Case, .Function:
            return .Procedural
        }
    }
}

public protocol ScopeTrackable {
    var scope: Scope { get }
}

public enum InstKind {
    case Type, Value, Operator, Enum, EnumCase, Struct, Class, Protocol, Extension

    private static func fromType(type: Inst.Type) -> InstKind {
        switch type {
        case is TypeInst.Type: return .Type
        case is ValueInst.Type: return .Value
        case is OperatorInst.Type: return .Operator
        case is EnumInst.Type: return .Enum
        case is EnumCaseInst.Type: return .EnumCase
        case is StructInst.Type: return .Struct
        case is ClassInst.Type: return .Class
        case is ProtocolInst.Type: return .Protocol
        case is ExtensionInst.Type: return .Extension
        default: assert(false, "<system error> invalid inst type.")
        }
    }
}

public enum RefKind {
    case Type, Value, Operator, EnumCase, ImplicitParameter

    private static func fromType(type: Ref.Type) -> RefKind {
        switch type {
        case is TypeRef.Type: return .Type
        case is ValueRef.Type: return .Value
        case is OperatorRef.Type: return .Operator
        case is EnumCaseRef.Type: return .EnumCase
        case is ImplicitParameterRef.Type: return .ImplicitParameter
        default: assert(false, "<system error> invalid ref type.")
        }
    }
}

public class Scope {
    public let type: ScopeType
    public let parent: Scope?
    public var children: [Scope] = []
    private var insts: [InstKind:[String:Inst]] = [:]
    private var refs: [RefKind:[Ref]] = [:]

    private init(_ type: ScopeType, _ parent: Scope?) {
        self.type = type
        self.parent = parent
        self.parent?.children.append(self)
    }

    private func createInst<ConcreteInst : Inst>(
        name: String, _ source: SourceTrackable, _ constructor: () -> ConcreteInst
    ) throws -> ConcreteInst {
        let kind = InstKind.fromType(ConcreteInst.self)
        guard insts[kind] != nil else {
            throw ErrorReporter.fatal(.InvalidScope(kind), source)
        }
        guard insts[kind]?[name] == nil else {
            throw ErrorReporter.fatal(.AlreadyExist(kind, name), source)
        }
        let i = constructor()
        insts[kind]?[name] = i
        return i
    }

    public func getInst(
        kind: InstKind, _ name: String, _ source: SourceTrackable
    ) throws -> Inst {
        if let i = insts[kind]?[name] {
            return i
        }
        guard let p = parent else {
            throw ErrorReporter.fatal(.NotExist(kind, name), source)
        }
        return try p.getInst(kind, name, source)
    }

    private func createRef<ConcreteRef: Ref>(
        source: SourceTrackable, _ constructor: () -> ConcreteRef
    ) throws -> ConcreteRef {
        let kind = RefKind.fromType(ConcreteRef.self)
        guard refs[kind] != nil else {
            throw ErrorReporter.fatal(.InvalidRefScope(kind), source)
        }
        let r = constructor()
        refs[kind]?.append(r)
        return r
    }

    private func printMembers() {
        print("Scope: \(type)")
        print("\ttypes: \(insts[.Type])")
        print("\tvalues: \(insts[.Value])")
        print("\toperators: \(insts[.Operator])")
        print("\tenums: \(insts[.Enum])")
        print("\tenumCases: \(insts[.EnumCase])")
        print("\tstructs: \(insts[.Struct])")
        print("\tclasses: \(insts[.Class])")
        print("\tprotocols: \(insts[.Protocol])")
        print("\textensions: \(insts[.Extension])")
        print("\ttypeRefs: \(refs[.Type])")
        print("\tvalueRefs: \(refs[.Value])")
        print("\toperatorRefs: \(refs[.Operator])")
        print("\tenumCaseRefs: \(refs[.EnumCase])")
        print("\timplicitParameterRefs: \(refs[.ImplicitParameter])")
    }
}

private class ModuleScope : Scope {
    init() {
        super.init(.File, nil)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

private class FileScope : Scope {
    init(_ parent: Scope) {
        super.init(.File, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

private class ImplicitScope : Scope {
    init(_ parent: Scope) {
        super.init(.Implicit, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

private class FlowScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }
}

private class FunctionScope : Scope {
    init(_ parent: Scope) {
        super.init(.Function, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }
}

private class EnumScope : Scope {
    init(_ parent: Scope) {
        super.init(.Enum, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = nil
        refs[.EnumCase] = nil
        refs[.ImplicitParameter] = nil
    }
}

private class StructScope : Scope {
    init(_ parent: Scope) {
        super.init(.Struct, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

private class ClassScope : Scope {
    init(_ parent: Scope) {
        super.init(.Class, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

private class ProtocolScope : Scope {
    init(_ parent: Scope) {
        super.init(.Protocol, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = nil
        insts[.Enum] = nil
        insts[.EnumCase] = nil
        insts[.Struct] = nil
        insts[.Class] = nil
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = nil
        refs[.EnumCase] = nil
        refs[.ImplicitParameter] = nil
    }
}

private class ExtensionScope : Scope {
    init(_ parent: Scope) {
        super.init(.Extension, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

public class ScopeManager {
    private static var importableModules: [String:() throws -> ()] = [:]
    private static var currentSourceScope: Scope = ModuleScope()
    private static var currentModuleScope: Scope = ModuleScope()
    private static var moduleImporting = false
    private static var currentScope: Scope {
        get { return moduleImporting ? currentModuleScope : currentSourceScope }
        set(scope) {
            if moduleImporting {
                currentModuleScope = scope
            } else {
                currentSourceScope = scope
            }
        }
    }
    private static var modules: [ModuleScope] = []

    public static func addImportableModule(
        name: String, _ importMethod: () throws -> ()
    ) {
        importableModules[name] = importMethod
    }

    public static func importModule(name: String, _ source: SourceTrackable) throws {
        guard let importMethod = importableModules[name] else {
            throw ErrorReporter.fatal(.NoSuchModule(name), source)
        }
        moduleImporting = true
        try importMethod()
        guard case let s as ModuleScope = currentModuleScope else {
            throw ErrorReporter.fatal(.UnresolvedScopeRemains, source)
        }
        modules.append(s)
        currentModuleScope = ModuleScope()
        moduleImporting = false
    }

    public static func enterScope(type: ScopeType) {
        switch type {
        case .Implicit:
            currentScope = ImplicitScope(currentScope)
        case .Module:
            assert(false, "<system error> duplicated module scope")
        case .File:
            if currentScope.type != .Module {
                assert(false, "<system error> file scope should be under a module scope")
            }
            currentScope = FileScope(currentScope)
        case .For, .ForIn, .While, .RepeatWhile, .If,
             .Guard, .Defer, .Do, .Catch, .Case:
            currentScope = FlowScope(type, currentScope)
        case .Function:
            currentScope = FunctionScope(currentScope)
        case .Enum:
            currentScope = EnumScope(currentScope)
        case .Struct:
            currentScope = StructScope(currentScope)
        case .Class:
            currentScope = ClassScope(currentScope)
        case .Protocol:
            currentScope = ProtocolScope(currentScope)
        case .Extension:
            currentScope = ExtensionScope(currentScope)
        }
    }

    public static func enterImplicitScope() {
        if currentScope.type.policy == .Procedural {
            currentScope = ImplicitScope(currentScope)
        }
    }

    public static func leaveScope(
        type: ScopeType, _ source: SourceTrackable?
    ) throws -> Scope {
        while currentScope.type == .Implicit {
            guard let s = currentScope.parent else {
                throw ErrorReporter.fatal(.LeavingModuleScope, source)
            }
            currentScope.printMembers()
            currentScope = s
        }
        guard currentScope.type == type else {
            throw ErrorReporter.fatal(
                .ScopeTypeMismatch(currentScope.type, type), source
            )
        }
        guard let parent = currentScope.parent else {
            throw ErrorReporter.fatal(.LeavingModuleScope, source)
        }
        let child = currentScope
        currentScope = parent
        child.printMembers()
        return child
    }

    // TODO access levelを引数に渡す
    public static func createType(
        name: String, _ source: SourceTrackable
    ) throws -> TypeInst {
        return try currentScope.createInst(name, source, { TypeInst(name, source) })
    }

    public static func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool? = nil
    ) throws -> ValueInst {
        return try currentScope.createInst(
            name, source, { ValueInst(name, source, isVariable: isVariable) }
        )
    }

    public static func createOperator(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorInst {
        return try currentScope.createInst(
            name, source, { OperatorInst(name, source) }
        )
    }

    public static func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) throws -> EnumInst {
        return try currentScope.createInst(
            name, source, { EnumInst(name, source, node: node) }
        )
    }

    public static func createEnumCase(
        name: String, _ source: SourceTrackable
    ) throws -> EnumCaseInst {
        return try currentScope.createInst(
            name, source, { EnumCaseInst(name, source) }
        )
    }

    public static func createStruct(
        name: String, _ source: SourceTrackable, node: StructDeclaration
    ) throws -> StructInst {
        return try currentScope.createInst(
            name, source, { StructInst(name, source, node: node) }
        )
    }

    public static func createClass(
        name: String, _ source: SourceTrackable, node: ClassDeclaration
    ) throws -> ClassInst {
        return try currentScope.createInst(
            name, source, { ClassInst(name, source, node: node) }
        )
    }

    public static func createProtocol(
        name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) throws -> ProtocolInst {
        return try currentScope.createInst(
            name, source, { ProtocolInst(name, source, node: node) }
        )
    }

    public static func createExtension(
        name: String, _ source: SourceTrackable, node: ExtensionDeclaration
    ) throws -> ExtensionInst {
        return try currentScope.createInst(
            name, source, { ExtensionInst(name, source, node: node) }
        )
    }

    public static func createTypeRef(
        name: String, _ source: SourceTrackable
    ) throws -> TypeRef {
        return try currentScope.createRef(source, { TypeRef(name, source) })
    }

    public static func createValueRef(
        name: String, _ source: SourceTrackable
    ) throws -> ValueRef {
        return try currentScope.createRef(source, { ValueRef(name, source) })
    }

    public static func createOperatorRef(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorRef {
        return try currentScope.createRef(source, { OperatorRef(name, source) })
    }

    public static func createEnumCaseRef(
        name: String, _ source: SourceTrackable, className: String? = nil
    ) throws -> EnumCaseRef {
        return try currentScope.createRef(
            source, { EnumCaseRef(name, source, className: className) }
        )
    }

    public static func createImplicitParameterRef(
        index: Int, _ source: SourceTrackable
    ) throws -> ImplicitParameterRef {
        return try currentScope.createRef(
            source, { ImplicitParameterRef(index, source) }
        )
    }
}
