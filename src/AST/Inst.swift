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

public class TypeInst : Inst, CustomStringConvertible {
    override public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }

    public var description: String {
        return "(TypeInst \(name))"
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

public class OperatorInst : Inst, CustomStringConvertible {
    override public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }

    public var description: String {
        return "(TypeInst \(name))"
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
    override public init(_ name: String, _ source: SourceTrackable) {
        super.init(name, source)
    }

    public var description: String {
        return "(TypeInst \(name))"
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

public class ExtensionInst : Inst, CustomStringConvertible {
    private let node: ExtensionDeclaration

    public init(
        _ name: String, _ source: SourceTrackable, node: ExtensionDeclaration
    ) {
        self.node = node
        super.init(name, source)
    }

    public var description: String {
        return "(ExtensionInst \(name))"
    }
}

public class Ref<Identifier : Equatable> : SourceTrackable {
    private let id: Identifier
    private let info: SourceInfo
    public var sourceInfo: SourceInfo {
        return info
    }

    public init(_ id: Identifier, _ source: SourceTrackable) {
        self.id = id
        self.info = source.sourceInfo
    }
}

public class TypeRef : Ref<String>, CustomStringConvertible {
    override public init(_ id: String, _ source: SourceTrackable) {
        super.init(id, source)
    }

    public var description: String {
        return "(TypeRef \(id))"
    }
}

public class ValueRef : Ref<String>, CustomStringConvertible {
    override public init(_ id: String, _ source: SourceTrackable) {
        super.init(id, source)
    }

    public var description: String {
        return "(ValueRef \(id))"
    }
}

public class OperatorRef : Ref<String>, CustomStringConvertible {
    override public init(_ id: String, _ source: SourceTrackable) {
        super.init(id, source)
    }

    public var description: String {
        return "(OperatorRef \(id))"
    }
}

public class EnumCaseRef : Ref<String>, CustomStringConvertible {
    private let className: String?

    public init(_ id: String, _ source: SourceTrackable, className: String?) {
        self.className = className
        super.init(id, source)
    }

    public var description: String {
        return "(EnumCaseRef \(id))"
    }
}

public class ImplicitParameterRef : Ref<Int>, CustomStringConvertible {
    override public init(_ id: Int, _ source: SourceTrackable) {
        super.init(id, source)
    }

    public var description: String {
        return "(ImplicitParameterRef \(id))"
    }
}
