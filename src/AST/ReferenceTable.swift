public class BindingRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(BindingRef \(name))"
    } }
}

public class OperatorRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(OperatorRef \(name))"
    } }
}

public class ClassRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ClassRef \(name))"
    } }
}

public class StructRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(StructRef \(name))"
    } }
}

public class EnumRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(EnumRef \(name))"
    } }
}

public class EnumCaseRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(EnumCaseRef \(name))"
    } }
}

public class ProtocolRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ProtocolRef \(name))"
    } }
}

public class MemberRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(MemberRef \(name))"
    } }
}

public class TypeRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(TypeRef \(name))"
    } }
}

public class ExtensionRef : CustomStringConvertible {
    public let name: String

    public init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ExtensionRef \(name))"
    } }
}
