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

public class Scope {
    private let type: ScopeType
    private let parent: Scope?
    private var types: [String:TypeInst]?
    private var values: [String:ValueInst]?
    private var operators: [String:OperatorInst]?
    private var enums: [String:EnumInst]?
    private var enumCases: [String:EnumCaseInst]?
    private var structs: [String:StructInst]?
    private var classes: [String:ClassInst]?
    private var protocols: [String:ProtocolInst]?
    private var extensions: [String:ExtensionInst]?
    private var typeRefs: [(String, TypeRef)]?
    private var valueRefs: [(String, ValueRef)]?
    private var operatorRefs: [(String, OperatorRef)]?
    private var enumCaseRefs: [(String, EnumCaseRef)]?
    private var implicitParameterRefs: [(Int, ImplicitParameterRef)]?

    private init(_ type: ScopeType, _ parent: Scope?) {
        self.type = type
        self.parent = parent
    }

    private func createInst<ConcreteInst : Inst>(
        inout insts: [String:ConcreteInst]?, _ name: String, _ source: SourceTrackable,
        _ constructor: () -> ConcreteInst
    ) throws -> ConcreteInst {
        guard insts != nil else {
            throw ErrorReporter.fatal(.InvalidScope(ConcreteInst.self), source)
        }
        guard insts?[name] == nil else {
            throw ErrorReporter.fatal(.AlreadyExist(ConcreteInst.self, name), source)
        }
        let i = constructor()
        insts?[name] = i
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

    private func createType(
        name: String, _ source: SourceTrackable
    ) throws -> TypeInst {
        return try createInst(
            &types, name, source, { TypeInst(name, source) }
        )
    }

    private func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool?
    ) throws -> ValueInst {
        return try createInst(
            &values, name, source, { ValueInst(name, source, isVariable: isVariable) }
        )
    }

    private func createOperator(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorInst {
        return try createInst(
            &operators, name, source, { OperatorInst(name, source) }
        )
    }

    private func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) throws -> EnumInst {
        return try createInst(
            &enums, name, source, { EnumInst(name, source, node: node) }
        )
    }

    private func createEnumCase(
        name: String, _ source: SourceTrackable
    ) throws -> EnumCaseInst {
        return try createInst(
            &enumCases, name, source, { EnumCaseInst(name, source) }
        )
    }

    private func createStruct(
        name: String, _ source: SourceTrackable, node: StructDeclaration
    ) throws -> StructInst {
        return try createInst(
            &structs, name, source, { StructInst(name, source, node: node) }
        )
    }

    private func createClass(
        name: String, _ source: SourceTrackable, node: ClassDeclaration
    ) throws -> ClassInst {
        return try createInst(
            &classes, name, source, { ClassInst(name, source, node: node) }
        )
    }

    private func createProtocol(
        name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) throws -> ProtocolInst {
        return try createInst(
            &protocols, name, source, { ProtocolInst(name, source, node: node) }
        )
    }

    private func createExtension(
        name: String, _ source: SourceTrackable, node: ExtensionDeclaration
    ) throws -> ExtensionInst {
        return try createInst(
            &extensions, name, source, { ExtensionInst(name, source, node: node) }
        )
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
        print("\ttypes: \(types)")
        print("\tvalues: \(values)")
        print("\toperators: \(operators)")
        print("\tenums: \(enums)")
        print("\tenumCases: \(enumCases)")
        print("\tstructs: \(structs)")
        print("\tclasses: \(classes)")
        print("\tprotocols: \(protocols)")
        print("\textensions: \(extensions)")
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = [:]
        extensions = [:]
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = [:]
        extensions = [:]
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = [:]
        extensions = [:]
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = nil
        extensions = nil
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = nil
        extensions = nil
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = [:]
        structs = [:]
        classes = [:]
        protocols = nil
        extensions = nil
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = nil
        extensions = nil
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = nil
        structs = [:]
        classes = [:]
        protocols = nil
        extensions = nil
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
        types = [:]
        values = [:]
        operators = nil
        enums = nil
        enumCases = nil
        structs = nil
        classes = nil
        protocols = nil
        extensions = nil
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
        types = [:]
        values = [:]
        operators = [:]
        enums = [:]
        enumCases = [:]
        structs = [:]
        classes = [:]
        protocols = nil
        extensions = nil
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
        return try currentScope.createType(name, source)
    }

    public static func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool? = nil
    ) throws -> ValueInst {
        return try currentScope.createValue(name, source, isVariable: isVariable)
    }

    public static func createOperator(
        name: String, _ source: SourceTrackable
    ) throws -> OperatorInst {
        return try currentScope.createOperator(name, source)
    }

    public static func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) throws -> EnumInst {
        return try currentScope.createEnum(name, source, node: node)
    }

    public static func createEnumCase(
        name: String, _ source: SourceTrackable
    ) throws -> EnumCaseInst {
        return try currentScope.createEnumCase(name, source)
    }

    public static func createStruct(
        name: String, _ source: SourceTrackable, node: StructDeclaration
    ) throws -> StructInst {
        return try currentScope.createStruct(name, source, node: node)
    }

    public static func createClass(
        name: String, _ source: SourceTrackable, node: ClassDeclaration
    ) throws -> ClassInst {
        return try currentScope.createClass(name, source, node: node)
    }

    public static func createProtocol(
        name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) throws -> ProtocolInst {
        return try currentScope.createProtocol(name, source, node: node)
    }

    public static func createExtension(
        name: String, _ source: SourceTrackable, node: ExtensionDeclaration
    ) throws -> ExtensionInst {
        return try currentScope.createExtension(name, source, node: node)
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
