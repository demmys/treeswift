public protocol Nestable {
    func appendNestedTypes(name: String, _ inst: Inst)
    func appendNestedValues(name: String, _ inst: Inst)
}

public class Inst : Typeable, Nestable, SourceTrackable {
    public var type = TypeManager()
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

public class TypeInst : Inst {}

public class ConstantInst : Inst {}

public class VariableInst : Inst {}

public class FunctionInst : Inst {}

public class OperatorInst : Inst {
    public var implementation: FunctionInst! {
        didSet {
            self.type = implementation.type
        }
    }

    public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }
}

public class EnumInst : Inst {
    public var node: EnumDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: EnumDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }
}

public class EnumCaseInst : Inst {
    public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }
}

public class StructInst : Inst {
    public var node: StructDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: StructDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }
}

public class ClassInst : Inst {
    public var node: ClassDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: ClassDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }
}

public class ProtocolInst : Inst {
    private let node: ProtocolDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: ProtocolDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }
}

public enum RefIdentifier {
    case Name(String)
    case Index(Int)
}

public class Ref : Typeable, SourceTrackable {
    public let id: RefIdentifier
    public var inst: Inst!
    private var onResolved: [() throws -> ()] = []
    public var type = TypeManager()
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
        onResolved.append({
            self.type = self.inst.type
        })
    }
}

public typealias NestedTypeSpecifier = (String, [Type]?, SourceTrackable)

public class TypeRef : Ref, Nestable {
    let nests: [NestedTypeSpecifier]
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
}

public class ValueRef : Ref {
    public init(_ name: String, _ source: SourceTrackable) {
        super.init(.Name(name), source)
    }
}

public class OperatorRef : Ref {
    public let impl: FunctionInst?

    public init(
        _ name: String, _ source: SourceTrackable, _ impl: FunctionInst? = nil
    ) {
        self.impl = impl
        super.init(.Name(name), source)
        onResolved.append({
            if let i = self.impl {
                if case let operatorInst as OperatorInst = self.inst {
                    operatorInst.implementation = i
                }
            }
        })
    }
}

public class EnumCaseRef : Ref {
    private let className: String?

    public init(_ name: String, _ source: SourceTrackable, className: String?) {
        self.className = className
        super.init(.Name(name), source)
    }
}

public class ImplicitParameterRef : Ref {
    public init(_ index: Int, _ source: SourceTrackable) {
        super.init(.Index(index), source)
    }
}
