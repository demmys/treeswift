public protocol Nestable {
    func appendNestedTypes(name: String, _ inst: Inst)
    func appendNestedValues(name: String, _ inst: Inst)
}

public class Inst : Typeable, Nestable, SourceTrackable {
    public var type = TypeCandidate()
    public let name: String
    public var accessLevel: AccessLevel?
    private let info: SourceInfo
    public var sourceInfo: SourceInfo {
        return info
    }
    public var memberTypes: [String:Inst] = [:]
    public var memberValues: [String:Inst] = [:]

    public init(
        _ name: String, _ source: SourceTrackable, _ memberTypes: [Inst] = []
    ) {
        self.name = name
        self.info = source.sourceInfo
        for inst in memberTypes {
            appendNestedTypes(inst.name, inst)
        }
    }

    public func appendNestedTypes(name: String, _ inst: Inst) {
        self.memberTypes[name] = inst
    }

    public func appendNestedValues(name: String, _ inst: Inst) {
        self.memberValues[name] = inst
    }
}

public class TypeInst : Inst, CustomStringConvertible {
    public var description: String {
        return "(TypeInst \(name))"
    }
}

public class ConstantInst : Inst, CustomStringConvertible {
    public var description: String {
        return "(ConstantInst \(name))"
    }
}

public class VariableInst : Inst, CustomStringConvertible {
    public var description: String {
        return "(VariableInst \(name))"
    }
}

public class FunctionInst : Inst, CustomStringConvertible {
    public var description: String {
        return "(FunctionInst \(name))"
    }
}

public class OperatorInst : Inst, CustomStringConvertible {
    public var implementations: [FunctionInst] = []

    public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }

    public var description: String {
        return "(OperatorInst \(name) \(implementations))"
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
        return "(EnumInst \(name) \(memberTypes) \(memberValues))"
    }
}

public class EnumCaseInst : Inst, CustomStringConvertible {
    public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }

    public var description: String {
        return "(EnumCaseInst \(name))"
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
        return "(StructInst \(name) \(memberTypes) \(memberValues))"
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
        return "(ClassInst \(name) \(memberTypes) \(memberValues))"
    }
}

public class ProtocolInst : Inst, CustomStringConvertible {
    private let node: ProtocolDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }

    public var description: String {
        return "(ProtocolInst \(name) \(memberTypes) \(memberValues))"
    }
}

public enum RefIdentifier : CustomStringConvertible{
    case Name(String)
    case Index(Int)

    public var description: String {
        switch self {
        case let .Name(n): return n
        case let .Index(i): return "$\(i)"
        }
    }
}

public class Ref : Typeable, SourceTrackable {
    public let id: RefIdentifier
    public var inst: Inst!
    private var onResolved: [() throws -> ()] = []
    public var type = TypeCandidate()
    private let info: SourceInfo
    public var sourceInfo: SourceInfo { return info }

    func resolvedCallback() throws {
        for callback in onResolved {
            try callback()
        }
    }

    public init(_ id: RefIdentifier, _ source: SourceTrackable) {
        self.id = id
        self.info = source.sourceInfo
    }
}

public typealias NestedTypeSpecifier = (String, [Type]?, SourceTrackable)

public class TypeRef : Ref, Nestable, CustomStringConvertible {
    private let nests: [NestedTypeSpecifier]
    private var memberTypes: [String:Inst] = [:]
    private var memberValues: [String:Inst] = [:]

    public init(
        _ name: String, _ source: SourceTrackable, _ nests: [NestedTypeSpecifier]
    ) {
        self.nests = nests
        super.init(.Name(name), source)
        onResolved.append(resolveNests)
    }

    private func resolveNests() throws {
        for (name, _, source) in nests {
            guard let child = inst.memberTypes[name] else {
                throw ErrorReporter.instance.fatal(
                    .NoNestedType(parent: inst.name, child: name), source
                )
            }
            inst = child
        }
    }

    func extendInst() {
        for (name, inst) in memberTypes {
            self.inst.appendNestedTypes(name, inst)
        }
        for (name, inst) in memberValues {
            self.inst.appendNestedValues(name, inst)
        }
    }

    public func appendNestedTypes(name: String, _ inst: Inst) {
        self.memberTypes[name] = inst
    }

    public func appendNestedValues(name: String, _ inst: Inst) {
        self.memberValues[name] = inst
    }

    public var description: String {
        return "(TypeRef \(id) \(nests) \(inst))"
    }
}

public class ValueRef : Ref, CustomStringConvertible {
    public init(_ name: String, _ source: SourceTrackable) {
        super.init(.Name(name), source)
    }

    public var description: String {
        return "(ValueRef \(id) \(inst))"
    }
}

public class OperatorRef : Ref, CustomStringConvertible {
    public let impl: FunctionInst?

    public init(
        _ name: String, _ source: SourceTrackable, _ impl: FunctionInst? = nil
    ) {
        self.impl = impl
        super.init(.Name(name), source)
        onResolved.append({
            if let i = self.impl {
                if case let operatorInst as OperatorInst = self.inst {
                    operatorInst.implementations.append(i)
                }
            }
        })
    }

    public var description: String {
        return "(OperatorRef \(id) \(inst) \(impl))"
    }
}

public class EnumCaseRef : Ref, CustomStringConvertible {
    private let className: String?

    public init(_ name: String, _ source: SourceTrackable, className: String?) {
        self.className = className
        super.init(.Name(name), source)
    }

    public var description: String {
        return "(EnumCaseRef \(id) \(inst))"
    }
}

public class ImplicitParameterRef : Ref, CustomStringConvertible {
    public init(_ index: Int, _ source: SourceTrackable) {
        super.init(.Index(index), source)
    }

    public var description: String {
        return "(ImplicitParameterRef \(id) \(inst))"
    }
}
