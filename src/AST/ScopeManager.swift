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
    private var values: [String:ValueInst]?
    private var enums: [String:EnumInst]?
    private var structs: [String:StructInst]?
    private var classes: [String:ClassInst]?
    private var valueRefs: [String:UnresolvedValueRef]?
    private var implicitParameterRefs: [Int:UnresolvedImplicitParameterRef]?

    private init(_ type: ScopeType, _ parent: Scope?) {
        self.type = type
        self.parent = parent
    }

    private func createInst<T : Inst>(
        inout insts: [String:T]?, _ name: String, _ source: SourceTrackable,
        _ constructor: () -> T
    ) throws -> T {
        guard insts != nil else {
            throw ErrorReporter.fatal(.InvalidScope(T.self), source)
        }
        guard insts?[name] == nil else {
            throw ErrorReporter.fatal(.AlreadyExist(T.self, name), source)
        }
        let i = constructor()
        insts?[name] = i
        return i
    }

    private func createUnresolvedRef<T : UnresolvedRef>(
        inout refs: [String:T]?, _ name: String, _ source: SourceTrackable,
        _ constructor: () -> T
    ) throws -> T {
        guard refs != nil else {
            throw ErrorReporter.fatal(.InvalidRefScope(T.self), source)
        }
        let i = constructor()
        refs?[name] = i
        return i
    }

    private func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool?
    ) throws -> ValueInst {
        return try createInst(
            &values, name, source, { ValueInst(name, source, isVariable: isVariable) }
        )
    }

    private func createUnresolvedValueRef(
        name: String, _ source: SourceTrackable
    ) throws -> UnresolvedValueRef {
        return try createUnresolvedRef(
            &valueRefs, name, source, { UnresolvedValueRef(name, source) }
        )
    }

    public func createUnresolvedImplicitParameterRef(
        index: Int, _ source: SourceTrackable
    ) throws -> UnresolvedImplicitParameterRef {
        guard implicitParameterRefs != nil else {
            throw ErrorReporter.fatal(.InvalidImplicitParameterRefScope, source)
        }
        let i = UnresolvedImplicitParameterRef(index, source)
        implicitParameterRefs?[index] = i
        return i
    }

    private func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) throws -> EnumInst {
        return try createInst(
            &enums, name, source, { EnumInst(name, source, node: node) }
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
}

private class GlobalScope : Scope {
    init() {
        super.init(.Global, nil)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class FileScope : Scope {
    init(_ parent: Scope) {
        super.init(.File, parent)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class ValueBindingScope : Scope {
    init(_ parent: Scope) {
        super.init(.ValueBinding, parent)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class FlowScope : Scope {
    init(_ type: ScopeType, _ parent: Scope) {
        super.init(type, parent)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class FunctionScope : Scope {
    init(_ parent: Scope) {
        super.init(.Function, parent)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = [:]
    }
}

private class EnumScope : Scope {
    init(_ parent: Scope) {
        super.init(.Enum, parent)
        values = nil
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class StructScope : Scope {
    init(_ parent: Scope) {
        super.init(.Struct, parent)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class ClassScope : Scope {
    init(_ parent: Scope) {
        super.init(.Class, parent)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class ProtocolScope : Scope {
    init(_ parent: Scope) {
        super.init(.Protocol, parent)
        values = nil
        enums = nil
        structs = nil
        classes = nil
        valueRefs = [:]
        implicitParameterRefs = nil
    }
}

private class ExtensionScope : Scope {
    init(_ parent: Scope) {
        super.init(.Extension, parent)
        values = nil
        enums = [:]
        structs = [:]
        classes = [:]
        valueRefs = [:]
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
        guard currentScope.type != type else {
            throw ErrorReporter.fatal(.ScopeTypeMismatch, source)
        }
        guard let s = currentScope.parent else {
            throw ErrorReporter.fatal(.LeavingGlobalScope, source)
        }
        let past = currentScope
        currentScope = s
        return past
    }

    public static func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool? = nil
    ) throws -> ValueInst {
        return try currentScope.createValue(name, source, isVariable: isVariable)
    }

    public static func createUnresolvedValueRef(
        name: String, _ source: SourceTrackable
    ) throws -> UnresolvedValueRef {
        return try currentScope.createUnresolvedValueRef(name, source)
    }

    public static func createUnresolvedImplicitParameterRef(
        index: Int, _ source: SourceTrackable
    ) throws -> UnresolvedImplicitParameterRef {
        return try currentScope.createUnresolvedImplicitParameterRef(index, source)
    }

    public static func createEnum(
        name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) throws -> EnumInst {
        return try currentScope.createEnum(name, source, node: node)
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
}

public class Inst : SourceTrackable {
    private let name: String
    private let info: SourceInfo
    public var sourceInfo: SourceInfo {
        return info
    }

    public init(_ name: String, _ source: SourceTrackable) {
        self.name = name
        self.info = source.sourceInfo
    }
}

public class ValueInst : Inst, CustomStringConvertible {
    public var isVariable: Bool!

    public init(
        _ name: String, _ source: SourceTrackable, isVariable: Bool? = nil
    ) {
        super.init(name, source)
        self.isVariable = isVariable
    }

    public var description: String {
        return "(ValueInst \(name) is-variable: \(isVariable))"
    }
}

public class EnumInst : Inst, CustomStringConvertible {
    public var node: EnumDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }

    public var description: String {
        return "(EnumInst \(name))"
    }
}

public class StructInst : Inst, CustomStringConvertible {
    public var node: StructDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: StructDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }

    public var description: String {
        return "(StructInst \(name))"
    }
}

public class ClassInst : Inst, CustomStringConvertible {
    public var node: ClassDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: ClassDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }

    public var description: String {
        return "(ClassInst \(name))"
    }
}

public class UnresolvedRef : SourceTrackable {
    private let name: String
    private let info: SourceInfo
    public var sourceInfo: SourceInfo {
        return info
    }

    public init(_ name: String, _ source: SourceTrackable) {
        self.name = name
        self.info = source.sourceInfo
    }
}

public class UnresolvedValueRef : UnresolvedRef, CustomStringConvertible {
    public var description: String {
        return "(UnresolvedValueRef \(index))"
    }
}

public class UnresolvedImplicitParameterRef : SourceTrackable, CustomStringConvertible {
    private let index: Int
    private let info: SourceInfo
    public var sourceInfo: SourceInfo {
        return info
    }

    public init(_ index: Int, _ source: SourceTrackable) {
        self.index = index
        self.info = source.sourceInfo
    }

    public var description: String {
        return "(UnresolvedImplicitParameterRef \(index))"
    }
}
