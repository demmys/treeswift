import Util

public enum ScopeType {
    case Global, File
    case For, ForIn, While, RepeatWhile, If, Guard, Defer, Do, Catch, Case
}

private class Scope {
    let type: ScopeType
    var values: [String:ValueInst]?

    init(_ type: ScopeType) {
        self.type = type
    }

    func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool
    ) throws -> ValueInst {
        guard values != nil else {
            throw ErrorReporter.fatal(.InvalidVariableScope, source)
        }
        guard getValue(name) == nil else {
            throw ErrorReporter.fatal(.VariableAlreadyExist(name), source)
        }
        let v = ValueInst(name, source, isVariable: isVariable)
        values?[name] = v
        return v
    }

    func getValue(name: String) -> ValueInst? {
        return values?[name]
    }
}

private class GlobalScope : Scope {
    init() {
        super.init(.Global)
        values = [:]
    }
}

private class FileScope : Scope {
    init() {
        super.init(.File)
        values = [:]
    }
}

private class FlowScope : Scope {
    override init(_ type: ScopeType) {
        super.init(type)
        values = [:]
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
        }
    }

    public static func leaveScope(type: ScopeType, _ source: SourceTrackable) throws {
        guard currentScope.type != type else {
            throw ErrorReporter.fatal(.ScopeTypeMismatch, source)
        }
        guard let s = scopeStack.popLast() else {
            throw ErrorReporter.fatal(.LeavingGlobalScope, source)
        }
        currentScope = s
    }

    public static func createValue(
        name: String, _ source: SourceTrackable, isVariable: Bool = false
    ) throws -> ValueInst {
        return try currentScope.createValue(name, source, isVariable: isVariable)
    }

    public static func getValue(
        name: String, _ source: SourceTrackable
    ) throws -> ValueInst {
        if let i = findInst({ (s: Scope) -> ValueInst? in s.getValue(name) }) {
            return i
        }
        throw ErrorReporter.fatal(.VariableNotExist(name), source)
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

public class ValueInst : Inst {
    private let isVariable: Bool

    public init(_ name: String, _ source: SourceTrackable, isVariable: Bool) {
        self.isVariable = isVariable
        super.init(name, source)
    }
}
