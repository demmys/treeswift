public enum MemberPolicy {
    case Declarative, Procedural, Transparent
}

public enum ScopeType {
    case Global, File
    case ValueBinding
    case For, ForIn, While, RepeatWhile, If, Guard, Defer, Do, Catch, Case
    case Function, Enum, Struct, Class, Protocol, Extension

    var policy: MemberPolicy {
        switch self {
        case .Global, .Enum, Struct, .Class, .Protocol, .Extension:
            return .Declarative
        case .File, .For, .ForIn, .While, .RepeatWhile, .If, .Guard, .Defer,
             .Do, .Catch, .Case, .Function:
            return .Procedural
        case .ValueBinding:
            return .Transparent
        }
    }
}

public protocol ScopeTrackable {
    var scope: Scope { get }
}

public enum InstKind {
    case Type, Value, Operator, Enum, EnumCase, Struct, Class, Protocol, Extension
}

public class Scope {
    public let type: ScopeType
    public let parent: Scope?
    public var children: [Scope] = []
    private var insts: [InstKind:[String:Inst]] = [:]
    private var typeRefs: [(String, TypeRef)]?
    private var valueRefs: [(String, ValueRef)]?
    private var operatorRefs: [(String, OperatorRef)]?
    private var enumCaseRefs: [(String, EnumCaseRef)]?
    private var implicitParameterRefs: [(Int, ImplicitParameterRef)]?

    private init(_ type: ScopeType, _ parent: Scope?) {
        self.type = type
        self.parent = parent
        self.parent?.children.append(self)
    }

    private func createInst<ConcreteInst : Inst>(
        kind: InstKind, _ name: String, _ source: SourceTrackable,
        _ constructor: () -> ConcreteInst
    ) throws -> ConcreteInst {
        guard insts[kind] != nil else {
            throw ErrorReporter.fatal(.InvalidScope(ConcreteInst.self), source)
        }
        guard insts[kind]?[name] == nil else {
            throw ErrorReporter.fatal(.AlreadyExist(ConcreteInst.self, name), source)
        }
        let i = constructor()
        insts[kind]?[name] = i
        return i
    }

    private func createRef<Identifier, ConcreteRef : Ref<Identifier>>(
        inout refs: [(Identifier, ConcreteRef)]?, _ id: Identifier,
        _ source: SourceTrackable, _ constructor: () -> ConcreteRef,
        _ errorMessage: ErrorMessage
    ) throws -> ConcreteRef {
        guard refs != nil else {
            throw ErrorReporter.fatal(errorMessage, source)
        }
        let r = constructor()
        refs?.append(id, r)
        return r
    }

    private func createTypeRef(
        id: String, _ source: SourceTrackable
    ) throws -> TypeRef {
        return try createRef(
            &typeRefs, id, source, { TypeRef(id, source) }, .InvalidTypeRefScope
        )
    }

    private func createValueRef(
        id: String, _ source: SourceTrackable
    ) throws -> ValueRef {
        return try createRef(
            &valueRefs, id, source, { ValueRef(id, source) }, .InvalidValueRefScope
        )
    }

    private func createOperatorRef(
        id: String, _ source: SourceTrackable
    ) throws -> OperatorRef {
        return try createRef(
            &operatorRefs, id, source, { OperatorRef(id, source) },
            .InvalidOperatorRefScope
        )
    }

    private func createEnumCaseRef(
        id: String, _ source: SourceTrackable, className: String?
    ) throws -> EnumCaseRef {
        return try createRef(
            &enumCaseRefs, id, source, { EnumCaseRef(id, source, className: className) },
            .InvalidEnumCaseRefScope
        )
    }

    public func createImplicitParameterRef(
        id: Int, _ source: SourceTrackable
    ) throws -> ImplicitParameterRef {
        return try createRef(
            &implicitParameterRefs, id, source, { ImplicitParameterRef(id, source) },
            .InvalidImplicitParameterRefScope
        )
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
        print("\ttypeRefs: \(typeRefs)")
        print("\tvalueRefs: \(valueRefs)")
        print("\toperatorRefs: \(operatorRefs)")
        print("\tenumCaseRefs: \(enumCaseRefs)")
        print("\timplicitParameterRefs: \(implicitParameterRefs)")
    }
}

private class GlobalScope : Scope {
    init() {
        super.init(.Global, nil)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = nil
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
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = nil
    }
}

private class ValueBindingScope : Scope {
    init(_ parent: Scope) {
        super.init(.ValueBinding, parent)
        insts[.Type] = [:]
        insts[.Value] = [:]
        insts[.Operator] = [:]
        insts[.Enum] = [:]
        insts[.EnumCase] = nil
        insts[.Struct] = [:]
        insts[.Class] = [:]
        insts[.Protocol] = [:]
        insts[.Extension] = [:]
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = nil
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
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = []
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
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = []
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
        typeRefs = []
        valueRefs = nil
        operatorRefs = nil
        enumCaseRefs = nil
        implicitParameterRefs = nil
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
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = nil
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
        typeRefs = []
        valueRefs = []
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = nil
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
        typeRefs = []
        valueRefs = nil
        operatorRefs = nil
        enumCaseRefs = nil
        implicitParameterRefs = nil
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
        typeRefs = []
        valueRefs = nil
        operatorRefs = []
        enumCaseRefs = []
        implicitParameterRefs = nil
    }
}

public class ScopeManager {
    private static var globalScope: GlobalScope = GlobalScope()
    private static var currentScope: Scope = globalScope

    public static func enterScope(type: ScopeType) {
        switch type {
        case .Global:
            assert(false, "<system error> duplicated global scope")
        case .File:
            currentScope = FileScope(currentScope)
        case .ValueBinding:
            guard currentScope.type.policy != .Declarative else {
                return
            }
            currentScope = ValueBindingScope(currentScope)
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

    public static func leaveScope(
        type: ScopeType, _ source: SourceTrackable?
    ) throws -> Scope {
        while currentScope.type == .ValueBinding {
            guard let s = currentScope.parent else {
                throw ErrorReporter.fatal(.LeavingGlobalScope, source)
            }
            currentScope.printMembers()
            currentScope = s
        }
        guard currentScope.type == type else {
            throw ErrorReporter.fatal(
                .ScopeTypeMismatch(currentScope.type, type), source
            )
        }
        guard let s = currentScope.parent else {
            throw ErrorReporter.fatal(.LeavingGlobalScope, source)
        }
        let past = currentScope
        currentScope = s
        past.printMembers()
        return past
    }

    public static func createType(
        name: String, _ source: SourceTrackable
    ) throws -> TypeInst {
        return try currentScope.createInst(
            .Type, name, source, { TypeInst(name, source) }
        )
    }

    public static func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool? = nil
    ) throws -> ValueInst {
        return try currentScope.createInst(
            .Value, name, source, { ValueInst(name, source, isVariable: isVariable) }
        )
    }

    public static func createOperator(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorInst {
        return try currentScope.createInst(
            .Operator, name, source, { OperatorInst(name, source) }
        )
    }

    public static func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) throws -> EnumInst {
        return try currentScope.createInst(
            .Enum, name, source, { EnumInst(name, source, node: node) }
        )
    }

    public static func createEnumCase(
        name: String, _ source: SourceTrackable
    ) throws -> EnumCaseInst {
        return try currentScope.createInst(
            .EnumCase, name, source, { EnumCaseInst(name, source) }
        )
    }

    public static func createStruct(
        name: String, _ source: SourceTrackable, node: StructDeclaration
    ) throws -> StructInst {
        return try currentScope.createInst(
            .Struct, name, source, { StructInst(name, source, node: node) }
        )
    }

    public static func createClass(
        name: String, _ source: SourceTrackable, node: ClassDeclaration
    ) throws -> ClassInst {
        return try currentScope.createInst(
            .Class, name, source, { ClassInst(name, source, node: node) }
        )
    }

    public static func createProtocol(
        name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) throws -> ProtocolInst {
        return try currentScope.createInst(
            .Protocol, name, source, { ProtocolInst(name, source, node: node) }
        )
    }

    public static func createExtension(
        name: String, _ source: SourceTrackable, node: ExtensionDeclaration
    ) throws -> ExtensionInst {
        return try currentScope.createInst(
            .Extension, name, source, { ExtensionInst(name, source, node: node) }
        )
    }

    public static func createTypeRef(
        name: String, _ source: SourceTrackable
    ) throws -> TypeRef {
        return try currentScope.createTypeRef(name, source)
    }

    public static func createValueRef(
        name: String, _ source: SourceTrackable
    ) throws -> ValueRef {
        return try currentScope.createValueRef(name, source)
    }

    public static func createOperatorRef(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorRef {
        return try currentScope.createOperatorRef(name, source)
    }

    public static func createEnumCaseRef(
        name: String, _ source: SourceTrackable, className: String? = nil
    ) throws -> EnumCaseRef {
        return try currentScope.createEnumCaseRef(name, source, className: className)
    }

    public static func createImplicitParameterRef(
        index: Int, _ source: SourceTrackable
    ) throws -> ImplicitParameterRef {
        return try currentScope.createImplicitParameterRef(index, source)
    }
}
