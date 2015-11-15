public enum MemberPolicy {
    case Declarative, Procedural
}

public enum ScopeType {
    case Module, File
    case Implicit
    case For, ForIn, While, RepeatWhile, If, Guard, Defer, Do, Catch, Case
    case Function, VariableBlock, Initializer, Deinitializer, Subscript, Closure
    case Enum(Inst), Struct(Inst), Class(Inst), Protocol(Inst), Extension(TypeRef)

    var policy: MemberPolicy {
        switch self {
        case .Module, .Enum, Struct, .Class, .Protocol, .Extension:
            return .Declarative
        case .Implicit, .File, .For, .ForIn, .While, .RepeatWhile, .If, .Guard,
             .Defer, .Do, .Catch, .Case, .Function, .VariableBlock, .Initializer,
             .Deinitializer, .Subscript, .Closure:
            return .Procedural
        }
    }

    private var nestable: Nestable? {
        switch self {
        case let .Enum(i): return i
        case let .Struct(i): return i
        case let .Class(i): return i
        case let .Protocol(i): return i
        case let .Extension(r): return r
        default: return nil
        }
    }
}

public protocol ScopeTrackable {
    var scope: Scope { get }
}

public enum RefKind {
    case Type, Value, Operator, EnumCase, ImplicitParameter

    private static func fromInstType(type: Inst.Type) -> [RefKind] {
        switch type {
        case is TypeInst.Type: return [.Type]
        case is ConstantInst.Type: return [.Value]
        case is VariableInst.Type: return [.Value]
        case is FunctionInst.Type: return [.Value]
        case is OperatorInst.Type: return [.Operator]
        case is EnumInst.Type: return [.Type, .Value]
        case is EnumCaseInst.Type: return [.EnumCase]
        case is StructInst.Type: return [.Type, .Value]
        case is ClassInst.Type: return [.Type, .Value]
        case is ProtocolInst.Type: return [.Type]
        default: assert(false, "<system error> invalid inst type.")
        }
    }

    private static func fromRefType(type: Ref.Type) -> RefKind {
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
    private var modules: [String:Module]?
    private var insts: [RefKind:[String:Inst]]
    private var refs: [RefKind:[Ref]] = [:]
    public var explicitType: ScopeType {
        guard case .Implicit = type else {
            return type
        }
        guard let p = parent else {
            assert(false, "ImplicitScope with no parent.")
        }
        return p.explicitType
    }

    private init(_ type: ScopeType, _ parent: Scope?) {
        self.type = type
        self.parent = parent
        insts = [
            .Type: [:], .Value: [:], .Operator: [:], .EnumCase: [:],
            .ImplicitParameter: [:]
        ]
        self.parent?.children.append(self)
    }

    func importModule(
        name: String, _ module: Module, _ source: SourceTrackable?
    ) throws {
        guard modules != nil else {
            if case .Implicit = type, let p = parent {
                try p.importModule(name, module, source)
                return
            }
            throw ErrorReporter.instance.fatal(.InvalidScopeToImport, source)
        }
        modules?[name] = module
    }

    private func isPermittedInst(type: Inst.Type) -> Bool {
        return false
    }

    private func createInst<ConcreteInst : Inst>(
        name: String, _ source: SourceTrackable, _ accessLevel: AccessLevel?,
        _ constructor: () -> ConcreteInst
    ) throws -> ConcreteInst {
        var explicitScope: Scope?
        switch type {
        case .Implicit:
            var p = parent
            while p != nil, case .Implicit = p!.type {
                p = p!.parent
            }
            if p == nil {
                assert(false, "ImplicitScope with no parent.")
            }
            if case .File = p!.type {
                explicitScope = p
                fallthrough
            }
        case .File:
            if let al = accessLevel where al == .Private || al == .PrivateSet {
                break
            }
            guard let p = (explicitScope ?? self).parent else {
                assert(false, "ModuleScope not prepared.")
            }
            return try p.createInst(name, source, accessLevel, constructor)
        default:
            break
        }

        guard isPermittedInst(ConcreteInst.self) else {
            throw ErrorReporter.instance.fatal(.InvalidScope(ConcreteInst.self), source)
        }
        let inst = constructor()
        inst.accessLevel = accessLevel
        let kinds = RefKind.fromInstType(ConcreteInst.self)
        for kind in kinds {
            guard insts[kind]![name] == nil else {
                throw ErrorReporter.instance.fatal(.AlreadyExist(kind, name), source)
            }
            insts[kind]![name] = inst
        }
        if let nestable = type.nestable {
            for kind in kinds {
                switch kind {
                case .Type: nestable.appendNestedTypes(name, inst)
                case .Value: nestable.appendNestedValues(name, inst)
                default: break
                }
            }
        }
        return inst
    }

    private func createRef<ConcreteRef: Ref>(
        source: SourceTrackable, _ constructor: () -> ConcreteRef, resolve: Bool
    ) throws -> ConcreteRef {
        let kind = RefKind.fromRefType(ConcreteRef.self)
        guard refs[kind] != nil else {
            throw ErrorReporter.instance.fatal(.InvalidRefScope(kind), source)
        }
        let r = constructor()
        refs[kind]?.append(r)
        if resolve {
            guard let inst = try resolveRef(kind, r) else {
                throw ErrorReporter.instance.fatal(.NotExist(kind, r.id), r)
            }
            r.inst = inst
            try r.resolvedCallback()
        }
        return r
    }

    private func resolveRef(kind: RefKind, _ ref: Ref) throws -> Inst? {
        guard case let .Name(name) = ref.id else {
            throw ErrorReporter.instance.fatal(.ImplicitParameterIsNotImplemented, ref)
        }
        if let i = insts[kind]![name] {
            return i
        }
        if let ms = modules {
            for (_, m) in ms {
                if let i = try m.moduleScope.resolveRef(kind, ref) {
                    return i
                }
            }
        }
        guard let p = parent else {
            return nil
        }
        return try p.resolveRef(kind, ref)
    }

    private func resolveRefs() throws {
        for (kind, rs) in refs {
            guard rs.count > 0 else {
                continue
            }
            for r in rs {
                guard let inst = try resolveRef(kind, r) else {
                    throw ErrorReporter.instance.fatal(.NotExist(kind, r.id), r)
                }
                r.inst = inst
                try r.resolvedCallback()
            }
        }
        for child in children {
            try child.resolveRefs()
        }
    }

    private func printMembers() {
        print("\ttypes: \(insts[.Type])")
        print("\tvalues: \(insts[.Value])")
        print("\toperators: \(insts[.Operator])")
        print("\tenumCases: \(insts[.EnumCase])")
        print("\ttypeRefs: \(refs[.Type])")
        print("\tvalueRefs: \(refs[.Value])")
        print("\toperatorRefs: \(refs[.Operator])")
        print("\tenumCaseRefs: \(refs[.EnumCase])")
        print("\timplicitParameterRefs: \(refs[.ImplicitParameter])")
    }
}

private class ModuleScope : Scope {
    static let BUILTIN_INT1_TYPE = TypeInst("Int1", SourceInfo.PHANTOM)
    static let BUILTIN_INT32_TYPE = TypeInst("Int32", SourceInfo.PHANTOM)
    static let BUILTIN_INT64_TYPE = TypeInst("Int64", SourceInfo.PHANTOM)
    static let BUILTIN_RAWPOINTER_TYPE = TypeInst("RawPointer", SourceInfo.PHANTOM)
    static let BUILTIN_TYPE = TypeInst("Builtin", SourceInfo.PHANTOM, [
        BUILTIN_INT1_TYPE, BUILTIN_INT32_TYPE, BUILTIN_INT64_TYPE,
        BUILTIN_RAWPOINTER_TYPE
    ])

    init() {
        super.init(.Module, nil)
        modules = [:]
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
        insts[.Type] = ["Builtin": ModuleScope.BUILTIN_TYPE]
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return true
        case is OperatorInst.Type: return true
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class FileScope : Scope {
    var fileName: String!

    init(_ parent: Scope) {
        super.init(.File, parent)
        modules = [:]
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return true
        case is OperatorInst.Type: return true
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }

    override private func resolveRefs() throws {
        do {
            try super.resolveRefs()
        } catch let e {
            ErrorReporter.instance.bundle(fileName)
            throw e
        }
    }
}

private class ImplicitScope : Scope {
    init(_ parent: Scope) {
        super.init(.Implicit, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return true
        case is OperatorInst.Type: return true
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class FlowScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class FunctionScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class ClosureScope : Scope {
    init(_ parent: Scope) {
        super.init(.Closure, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class EnumScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = nil
        refs[.EnumCase] = nil
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return false
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return true
        default: return false
        }
    }
}

private class StructScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class ClassScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return true
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class ProtocolScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = nil
        refs[.EnumCase] = nil
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return false
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return false
        case is StructInst.Type: return false
        case is ClassInst.Type: return false
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

private class ExtensionScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = nil
        refs[.EnumCase] = nil
        refs[.ImplicitParameter] = nil
    }

    override private func isPermittedInst(type: Inst.Type) -> Bool {
        switch type {
        case is TypeInst.Type: return true
        case is ConstantInst.Type: return false
        case is VariableInst.Type: return true
        case is FunctionInst.Type: return true
        case is EnumInst.Type: return true
        case is StructInst.Type: return true
        case is ClassInst.Type: return true
        case is ProtocolInst.Type: return false
        case is OperatorInst.Type: return false
        case is EnumCaseInst.Type: return false
        default: return false
        }
    }
}

public class ScopeManager {
    public static var modules: [String:Module] = [:]
    private static var importableModules: [String:() throws -> [Declaration]] = [:]
    private static var currentScope: Scope = ModuleScope()
    private static var importingScopeStack: [Scope] = []
    private static var moduleParsing: Bool { return importingScopeStack.count > 0 }

    public static func addImportableModule(
        name: String, _ importMethod: () throws -> [Declaration]
    ) {
        importableModules[name] = importMethod
    }

    public static func importModule(name: String, _ source: SourceTrackable?) throws {
        if let module = modules[name] {
            try currentScope.importModule(name, module, source)
            if let nestedImportingScope = importingScopeStack.popLast() {
                currentScope = nestedImportingScope
            }
            return
        }
        guard let importMethod = importableModules[name] else {
            throw ErrorReporter.instance.fatal(.NoSuchModule(name), source)
        }
        importingScopeStack.append(currentScope)
        currentScope = ModuleScope()
        let declarations = try importMethod()
        // printScopes() // DEBUG
        guard case .Module = currentScope.type else {
            throw ErrorReporter.instance.fatal(.UnresolvedScopeRemains, source)
        }
        let module = Module(declarations: declarations, moduleScope: currentScope)
        modules[name] = module
        currentScope = importingScopeStack.popLast()!
        try currentScope.importModule(name, module, source)
    }

    public static func setFileName(fileName: String) {
        guard case let fileScope as FileScope = currentScope else {
            assert(false, "<system error> Cannot set file name to the current scope")
        }
        fileScope.fileName = fileName
    }

    public static func enterScope(type: ScopeType) {
        switch type {
        case .Implicit:
            currentScope = ImplicitScope(currentScope)
        case .Module:
            assert(false, "<system error> duplicated module scope")
        case .File:
            guard case .Module = currentScope.type else {
                assert(false, "<system error> file scope should be under a module scope")
            }
            currentScope = FileScope(currentScope)
        case .For, .ForIn, .While, .RepeatWhile, .If,
             .Guard, .Defer, .Do, .Catch, .Case:
            currentScope = FlowScope(type, currentScope)
        case .Function, .VariableBlock, .Initializer, .Deinitializer, .Subscript:
            currentScope = FunctionScope(type, currentScope)
        case .Closure:
            currentScope = ClosureScope(currentScope)
        case .Enum:
            currentScope = EnumScope(type, currentScope)
        case .Struct:
            currentScope = StructScope(type, currentScope)
        case .Class:
            currentScope = ClassScope(type, currentScope)
        case .Protocol:
            currentScope = ProtocolScope(type, currentScope)
        case .Extension:
            currentScope = ExtensionScope(type, currentScope)
        }
    }

    public static func enterImplicitScope() {
        if currentScope.type.policy == .Procedural {
            currentScope = ImplicitScope(currentScope)
        }
    }

    public static func leaveScope(source: SourceTrackable?) throws -> Scope {
        while case .Implicit = currentScope.type {
            guard let s = currentScope.parent else {
                throw ErrorReporter.instance.fatal(.LeavingModuleScope, source)
            }
            currentScope = s
        }
        guard let parent = currentScope.parent else {
            throw ErrorReporter.instance.fatal(.LeavingModuleScope, source)
        }
        if case let .Extension(r) = currentScope.type {
            r.extendInst()
        }
        let child = currentScope
        currentScope = parent
        return child
    }

    public static func createType(
        name: String, _ source: SourceTrackable, accessLevel: AccessLevel? = nil
    ) throws -> TypeInst {
        return try currentScope.createInst(
            name, source, accessLevel, { TypeInst(name, source) }
        )
    }

    public static func createConstant(
        name: String, _ source: SourceTrackable, accessLevel: AccessLevel? = nil
    ) throws -> ConstantInst {
        return try currentScope.createInst(
            name, source, accessLevel, { ConstantInst(name, source) }
        )
    }

    public static func createVariable(
        name: String, _ source: SourceTrackable, accessLevel: AccessLevel? = nil
    ) throws -> VariableInst {
        return try currentScope.createInst(
            name, source, accessLevel, { VariableInst(name, source) }
        )
    }

    public static func createFunction(
        name: String, _ source: SourceTrackable, accessLevel: AccessLevel? = nil
    ) throws -> FunctionInst {
        return try currentScope.createInst(
            name, source, accessLevel, { FunctionInst(name, source) }
        )
    }

    public static func createOperator(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorInst {
        return try currentScope.createInst(
            name, source, .Public, { OperatorInst(name, source) }
        )
    }

    public static func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration,
        accessLevel: AccessLevel? = nil
    ) throws -> EnumInst {
        return try currentScope.createInst(
            name, source, accessLevel, { EnumInst(name, source, node: node) }
        )
    }

    public static func createEnumCase(
        name: String, _ source: SourceTrackable
    ) throws -> EnumCaseInst {
        return try currentScope.createInst(
            name, source, nil, { EnumCaseInst(name, source) }
        )
    }

    public static func createStruct(
        name: String, _ source: SourceTrackable, node: StructDeclaration,
        accessLevel: AccessLevel? = nil
    ) throws -> StructInst {
        return try currentScope.createInst(
            name, source, accessLevel, { StructInst(name, source, node: node) }
        )
    }

    public static func createClass(
        name: String, _ source: SourceTrackable, node: ClassDeclaration,
        accessLevel: AccessLevel? = nil
    ) throws -> ClassInst {
        return try currentScope.createInst(
            name, source, accessLevel, { ClassInst(name, source, node: node) }
        )
    }

    public static func createProtocol(
        name: String, _ source: SourceTrackable, node: ProtocolDeclaration,
        accessLevel: AccessLevel? = nil
    ) throws -> ProtocolInst {
        return try currentScope.createInst(
            name, source, accessLevel, { ProtocolInst(name, source, node: node) }
        )
    }

    public static func createTypeRef(
        name: String, _ source: SourceTrackable, nests: [NestedTypeSpecifier] = [],
        resolve: Bool = false
    ) throws -> TypeRef {
        return try currentScope.createRef(
            source, { TypeRef(name, source, nests) },
            resolve: resolve || moduleParsing
        )
    }

    public static func createValueRef(
        name: String, _ source: SourceTrackable
    ) throws -> ValueRef {
        return try currentScope.createRef(
            source, { ValueRef(name, source) }, resolve: moduleParsing
        )
    }

    public static func createOperatorRef(
        name: String, _ source: SourceTrackable, impl: FunctionInst? = nil
    ) throws -> OperatorRef {
        return try currentScope.createRef(
            source, { OperatorRef(name, source, impl) }, resolve: moduleParsing
        )
    }

    public static func createEnumCaseRef(
        name: String, _ source: SourceTrackable, className: String? = nil
    ) throws -> EnumCaseRef {
        return try currentScope.createRef(
            source, { EnumCaseRef(name, source, className: className) },
            resolve: moduleParsing
        )
    }

    public static func createImplicitParameterRef(
        index: Int, _ source: SourceTrackable
    ) throws -> ImplicitParameterRef {
        return try currentScope.createRef(
            source, { ImplicitParameterRef(index, source) }, resolve: moduleParsing
        )
    }

    public static func resolveRefs() throws {
        guard case .Module = currentScope.type else {
            assert(false, "<system error> Parsing is not ended yet.")
        }
        try currentScope.resolveRefs()
    }

    public static func printScopes() {
        func printScope(scope: Scope) {
            print("\(scope.type)Scope {")
            scope.printMembers()
            print("")
            for child in scope.children {
                printScope(child)
            }
            print("}")
        }
        printScope(currentScope)
    }
}
