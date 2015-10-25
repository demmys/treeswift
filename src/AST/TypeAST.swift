public protocol Type : CustomStringConvertible {}

public class IdentifierType : Type {
    public let ref: TypeRef
    public let genArgs: [Type]?

    public init(_ r: TypeRef, _ g: [Type]?) {
        ref = r
        genArgs = g
    }
}

public class ArrayType : Type {
    public let elem: Type

    public init(_ e: Type) {
        elem = e
    }
}

public class DictionaryType : Type {
    public let key: Type
    public let value: Type

    public init(_ k: Type, _ v: Type) {
        key = k
        value = v
    }
}

public class TupleType : Type {
    public var elems: [TupleTypeElement] = []
    public var variadic: Bool = false

    public init() {}
}

public class TupleTypeElement {
    public var attrs: [Attribute] = []
    public var inOut: Bool = false
    public var label: String?
    public var type: Type!

    public init() {}
}

public class ProtocolCompositionType : Type {
    public var types: [IdentifierType] = []

    public init() {}
}

public class FunctionType : Type {
    public let arg: Type
    public let throwType: ThrowType
    public let ret: Type

    public init(_ a: Type, _ t: ThrowType, _ r: Type) {
        arg = a
        throwType = t
        ret = r
    }
}

public class OptionalType : Type {
    public let wrapped: Type

    public init(_ w: Type) {
        wrapped = w
    }
}

public class ImplicitlyUnwrappedOptionalType : Type {
    public let wrapped: Type

    public init(_ w: Type) {
        wrapped = w
    }
}

public class MetaType : Type {
    public let type: Type

    public init(_ t: Type) {
        type = t
    }
}

public class MetaProtocol : Type {
    public var proto: Type!

    public init(_ p: Type) {
        proto = p
    }
}
