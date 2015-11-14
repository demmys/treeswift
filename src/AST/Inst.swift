public class Inst : Typeable, SourceTrackable {
    public var type = TypeCandidate()
    public let name: String
    private let info: SourceInfo
    public var accessLevel: AccessLevel?
    public var nestedTypes: [String:Inst] = [:]
    public var members: [String:Inst] = [:]
    public var sourceInfo: SourceInfo {
        return info
    }

    public init(
        _ name: String, _ source: SourceTrackable, nestedTypes: [Inst] = []
    ) {
        self.name = name
        self.info = source.sourceInfo
        for inst in nestedTypes {
            self.nestedTypes[inst.name] = inst
        }
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
        return "(EnumInst \(name))"
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

public class ProtocolInst : Inst, CustomStringConvertible {
    private let node: ProtocolDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }

    public var description: String {
        return "(ProtocolInst \(name))"
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

public typealias NestedType = (String, [Type]?, SourceTrackable)

public class TypeRef : Ref, CustomStringConvertible {
    private let nestedTypes: [NestedType]

    public init(
        _ name: String, _ source: SourceTrackable, _ nested: [NestedType]
    ) {
        self.nestedTypes = nested
        super.init(.Name(name), source)
        onResolved.append(resolveNestedTypes)
    }

    private func resolveNestedTypes() throws {
        for (name, _, source) in nestedTypes {
            guard let child = inst.nestedTypes[name] else {
                throw ErrorReporter.instance.fatal(
                    .NoNestedType(parent: inst.name, child: name), source
                )
            }
            inst = child
        }
    }

    public var description: String {
        return "(TypeRef \(id) \(nestedTypes) \(inst))"
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
