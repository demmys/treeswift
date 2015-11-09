public enum MemberPolicy {
    case Declarative, Procedural
}

public enum ScopeType {
    case Module, File
    case Implicit
    case For, ForIn, While, RepeatWhile, If, Guard, Defer, Do, Catch, Case
    case Function, VariableBlock, Initializer, Deinitializer, Subscript
    case Closure, Enum, Struct, Class, Protocol, Extension

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
}

public protocol ScopeTrackable {
    var scope: Scope { get }
}

public enum InstKind {
    case Type, Constant, Variable, Function, Operator
    case Enum, EnumCase, Struct, Class, Protocol, Extension

    private static func fromType(type: Inst.Type) -> InstKind {
        switch type {
        case is TypeInst.Type: return .Type
        case is ConstantInst.Type: return .Constant
        case is VariableInst.Type: return .Variable
        case is FunctionInst.Type: return .Function
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
    private var modules: [String:ModuleInst]?
    private var insts: [InstKind:[String:Inst]] = [:]
    private var refs: [RefKind:[Ref]] = [:]
    public var explicitType: ScopeType {
        guard type == .Implicit else {
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
        self.parent?.children.append(self)
    }

    func importModule(
        name: String, _ module: ModuleInst, _ source: SourceTrackable?
    ) throws {
        guard modules != nil else {
            if type == .Implicit, let p = parent {
                try p.importModule(name, module, source)
                return
            }
            throw ErrorReporter.fatal(.InvalidScopeToImport, source)
        }
        modules?[name] = module
    }

    private func createInst<ConcreteInst : Inst>(
        name: String, _ source: SourceTrackable, _ accessLevel: AccessLevel?,
        _ constructor: () -> ConcreteInst
    ) throws -> ConcreteInst {
        var explicitScope: Scope?
        switch type {
        case .Implicit:
            var p = parent
            while p != nil && p!.type == .Implicit {
                p = p!.parent
            }
            if p == nil {
                assert(false, "ImplicitScope with no parent.")
            }
            if p!.type == .File {
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
        let kind = InstKind.fromType(ConcreteInst.self)
        guard insts[kind] != nil else {
            throw ErrorReporter.fatal(.InvalidScope(kind), source)
        }
        guard insts[kind]?[name] == nil else {
            throw ErrorReporter.fatal(.AlreadyExist(kind, name), source)
        }
        let i = constructor()
        if type == .Module, let al = accessLevel where al == .Public || al == .PublicSet {
            i.isPublic = true
        }
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
        print("\tmodules: \(modules)")
        print("\ttypes: \(insts[.Type])")
        print("\tconstants: \(insts[.Constant])")
        print("\tvariable: \(insts[.Variable])")
        print("\tfunctions: \(insts[.Function])")
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
        super.init(.Module, nil)
        modules = [:]
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        insts[.Operator] = [:]
        insts[.EnumCase] = nil
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
        modules = [:]
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        insts[.Operator] = [:]
        insts[.EnumCase] = nil
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
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        insts[.Operator] = [:]
        insts[.EnumCase] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }
}

private class FlowScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = []
    }
}

private class FunctionScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
        refs[.Type] = []
        refs[.Value] = []
        refs[.Operator] = []
        refs[.EnumCase] = []
        refs[.ImplicitParameter] = nil
    }
}

private class ClosureScope : Scope {
    init(_ parent: Scope) {
        super.init(.Closure, parent)
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
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
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = nil
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = [:]
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
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
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
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = [:]
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
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
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = nil
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = nil
        insts[.Struct] = nil
        insts[.Class] = nil
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
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
        modules = nil
        insts[.Type] = [:]
        insts[.Constant] = nil
        insts[.Variable] = [:]
        insts[.Function] = [:]
        insts[.Enum] = [:]
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = nil
        insts[.Extension] = nil
        insts[.Operator] = nil
        insts[.EnumCase] = nil
        refs[.Type] = []
        refs[.Value] = nil
        refs[.Operator] = nil
        refs[.EnumCase] = nil
        refs[.ImplicitParameter] = nil
    }
}

public class ScopeManager {
    private static var modules: [String:ModuleInst] = [:]
    private static var importableModules: [String:() throws -> [Declaration]] = [:]
    private static var currentScope: Scope = ModuleScope()
    private static var importingScopeStack: [Scope] = []

    public static func addImportableModule(
        name: String, _ importMethod: () throws -> [Declaration]
    ) {
        importableModules[name] = importMethod
    }

    public static func importModule(name: String, _ source: SourceTrackable?) throws {
        if let moduleInst = modules[name] {
            try currentScope.importModule(name, moduleInst, source)
            if let nestedImportingScope = importingScopeStack.popLast() {
                currentScope = nestedImportingScope
            }
            return
        }
        guard let importMethod = importableModules[name] else {
            throw ErrorReporter.fatal(.NoSuchModule(name), source)
        }
        importingScopeStack.append(currentScope)
        currentScope = ModuleScope()
        let declarations = try importMethod()
        guard case let moduleScope as ModuleScope = currentScope else {
            throw ErrorReporter.fatal(.UnresolvedScopeRemains, source)
        }
        let moduleInst = ModuleInst(
            name, module: Module(declarations: declarations, moduleScope: moduleScope)
        )
        modules[name] = moduleInst
        currentScope = importingScopeStack.popLast()!
        try currentScope.importModule(name, moduleInst, source)
    }

    public static func enterScope(type: ScopeType) {
        switch type {
        case .Implicit:
            currentScope = ImplicitScope(currentScope)
        case .Module:
            assert(false, "<system error> duplicated module scope")
        case .File:
            guard currentScope.type == .Module else {
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

    public static func createExtension(
        name: String, _ source: SourceTrackable, node: ExtensionDeclaration,
        accessLevel: AccessLevel? = nil
    ) throws -> ExtensionInst {
        return try currentScope.createInst(
            name, source, accessLevel, { ExtensionInst(name, source, node: node) }
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
