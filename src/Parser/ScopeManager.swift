import Util

public enum ScopeType {
    case Global, File
    case For, ForIn, While, RepeatWhile, If, Guard, Defer, Do, Catch, Case
    case Function, Enum, Struct, Class, Protocol, Extension
}

private class Scope {
    let type: ScopeType
    var values: [String:ValueInst]?
    var enums: [String:EnumInst]?
    var structs: [String:StructInst]?
    var classes: [String:ClassInst]?

    init(_ type: ScopeType) {
        self.type = type
    }

    func createValue(
        name: String, _ source: SourceTrackable, _ isVariable: Bool?
    ) throws -> ValueInst {
        guard values != nil else {
            throw ErrorReporter.fatal(.InvalidVariableScope, source)
        }
        guard getValue(name) == nil else {
            throw ErrorReporter.fatal(.VariableAlreadyExist(name), source)
        }
        let i = ValueInst(name, source, isVariable: isVariable)
        values?[name] = i
        return i
    }

    func getValue(name: String) -> ValueInst? {
        return values?[name]
    }

    func createEnum(name: String, _ source: SourceTrackable) throws -> EnumInst {
        guard enums != nil else {
            throw ErrorReporter.fatal(.InvalidEnumScope, source)
        }
        guard getEnum(name) == nil else {
            throw ErrorReporter.fatal(.EnumAlreadyExist(name), source)
        }
        let i = EnumInst(name, source)
        enums?[name] = i
        return i
    }

    func getEnum(name: String) -> EnumInst? {
        return enums?[name]
    }

    func createStruct(name: String, _ source: SourceTrackable) throws -> StructInst {
        guard structs != nil else {
            throw ErrorReporter.fatal(.InvalidStructScope, source)
        }
        guard getStruct(name) == nil else {
            throw ErrorReporter.fatal(.StructAlreadyExist(name), source)
        }
        let i = StructInst(name, source)
        structs?[name] = i
        return i
    }

    func getStruct(name: String) -> StructInst? {
        return structs?[name]
    }

    func createClass(name: String, _ source: SourceTrackable) throws -> ClassInst {
        guard classes != nil else {
            throw ErrorReporter.fatal(.InvalidClassScope, source)
        }
        guard getClass(name) == nil else {
            throw ErrorReporter.fatal(.ClassAlreadyExist(name), source)
        }
        let i = ClassInst(name, source)
        classes?[name] = i
        return i
    }

    func getClass(name: String) -> ClassInst? {
        return classes?[name]
    }
}

private class GlobalScope : Scope {
    init() {
        super.init(.Global)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class FileScope : Scope {
    init() {
        super.init(.File)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class FlowScope : Scope {
    override init(_ type: ScopeType) {
        super.init(type)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class FunctionScope : Scope {
    init() {
        super.init(.Function)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class EnumScope : Scope {
    init() {
        super.init(.Enum)
        values = nil
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class StructScope : Scope {
    init() {
        super.init(.Struct)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class ClassScope : Scope {
    init() {
        super.init(.Class)
        values = [:]
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

private class ProtocolScope : Scope {
    init() {
        super.init(.Protocol)
        values = nil
        enums = nil
        structs = nil
        classes = nil
    }
}

private class ExtensionScope : Scope {
    init() {
        super.init(.Extension)
        values = nil
        enums = [:]
        structs = [:]
        classes = [:]
    }
}

public class ScopeManager {
    private static var globalScope: GlobalScope = GlobalScope()
    private static var scopeStack: [Scope] = []
    private static var currentScope: Scope = globalScope

    public static func enterScope(type: ScopeType) {
        scopeStack.append(currentScope)
        switch type {
        case .Global:
            assert(false, "<system error> duplicated global scope")
        case .File:
            currentScope = FileScope()
        case .For, .ForIn, .While, .RepeatWhile, .If,
             .Guard, .Defer, .Do, .Catch, .Case:
            currentScope = FlowScope(type)
        case .Function:
            currentScope = FunctionScope()
        case .Enum:
            currentScope = EnumScope()
        case .Struct:
            currentScope = StructScope()
        case .Class:
            currentScope = ClassScope()
        case .Protocol:
            currentScope = ProtocolScope()
        case .Extension:
            currentScope = ExtensionScope()
        }
    }

    public static func leaveScope(type: ScopeType, _ source: SourceTrackable?) throws {
        guard currentScope.type != type else {
            throw ErrorReporter.fatal(.ScopeTypeMismatch, source)
        }
        guard let s = scopeStack.popLast() else {
            throw ErrorReporter.fatal(.LeavingGlobalScope, source)
        }
        currentScope = s
    }

    public static func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool? = nil
    ) throws -> ValueInst {
        return try currentScope.createValue(name, source, isVariable)
    }

    public static func getValue(
        name: String, _ source: SourceTrackable
    ) throws -> ValueInst {
        if let i = findInst({ (s: Scope) -> ValueInst? in s.getValue(name) }) {
            return i
        }
        throw ErrorReporter.fatal(.VariableNotExist(name), source)
    }

    public static func createEnum(
        name: String, _ source: SourceTrackable
    ) throws -> EnumInst {
        return try currentScope.createEnum(name, source)
    }

    public static func getEnum(
        name: String, _ source: SourceTrackable
    ) throws -> EnumInst {
        if let i = findInst({ (s: Scope) -> EnumInst? in s.getEnum(name) }) {
            return i
        }
        throw ErrorReporter.fatal(.EnumNotExist(name), source)
    }

    public static func createStruct(
        name: String, _ source: SourceTrackable
    ) throws -> StructInst {
        return try currentScope.createStruct(name, source)
    }

    public static func getStruct(
        name: String, _ source: SourceTrackable
    ) throws -> StructInst {
        if let i = findInst({ (s: Scope) -> StructInst? in s.getStruct(name) }) {
            return i
        }
        throw ErrorReporter.fatal(.StructNotExist(name), source)
    }

    public static func createClass(
        name: String, _ source: SourceTrackable
    ) throws -> ClassInst {
        return try currentScope.createClass(name, source)
    }

    public static func getClass(
        name: String, _ source: SourceTrackable
    ) throws -> ClassInst {
        if let i = findInst({ (s: Scope) -> ClassInst? in s.getClass(name) }) {
            return i
        }
        throw ErrorReporter.fatal(.ClassNotExist(name), source)
    }

    private static func findInst<T : Inst>(findScope: Scope -> T?) -> T? {
        if let inst = findScope(currentScope) {
            return inst
        }
        for var i = scopeStack.endIndex; i >= 0; --i {
            if let inst = findScope(scopeStack[i]) {
                return inst
            }
        }
        return nil
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
    public var description: String {
        return "(EnumInst \(name))"
    }
}

public class StructInst : Inst, CustomStringConvertible {
    public var description: String {
        return "(StructInst \(name))"
    }
}

public class ClassInst : Inst, CustomStringConvertible {
    public var description: String {
        return "(ClassInst \(name))"
    }
}
