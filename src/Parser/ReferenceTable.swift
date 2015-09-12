public class ValueRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ValueRef \(name))"
    } }
}

public class OperatorRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(OperatorRef \(name))"
    } }
}

public class ClassRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ClassRef \(name))"
    } }
}

public class StructRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(StructRef \(name))"
    } }
}

public class EnumRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(EnumRef \(name))"
    } }
}

public class EnumCaseRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(EnumCaseRef \(name))"
    } }
}

public class ProtocolRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ProtocolRef \(name))"
    } }
}

public class MemberRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(MemberRef \(name))"
    } }
}

public class TypeRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(TypeRef \(name))"
    } }
}

public class ExtensionRef : CustomStringConvertible {
    let name: String

    init(_ n: String) {
        name = n
    }

    public var description: String { get {
        return "(ExtensionRef \(name))"
    } }
}
