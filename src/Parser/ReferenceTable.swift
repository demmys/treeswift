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
