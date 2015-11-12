public protocol Typeable {
    var type: Type? { get set }
}

public protocol Type : Typeable, CustomStringConvertible {}

public typealias TypeAnnotation = (Type, attrs: [Attribute])

public class IdentifierType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let ref: TypeRef
    public let genArgs: [Type]?
    public let nestedTypes: [(String, [Type]?)]?

    public init(_ r: TypeRef, _ g: [Type]?, _ n: [(String, [Type]?)]?) {
        ref = r
        genArgs = g
        nestedTypes = n
    }
}

public class ArrayType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let elem: Type

    public init(_ e: Type) {
        elem = e
    }
}

public class DictionaryType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let key: Type
    public let value: Type

    public init(_ k: Type, _ v: Type) {
        key = k
        value = v
    }
}

public class TupleType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public var elems: [TupleTypeElement] = []

    public init() {}
}

public class TupleTypeElement {
    public var attrs: [Attribute] = []
    public var inOut: Bool = false
    public var variadic: Bool = false
    public var label: String?
    public var type: Type!

    public init() {}
}

public class ProtocolCompositionType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public var types: [IdentifierType] = []

    public init() {}
}

public class FunctionType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
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
    public var type: Type? {
        get { return self }
        set {}
    }
    public let wrapped: Type

    public init(_ w: Type) {
        wrapped = w
    }
}

public class ImplicitlyUnwrappedOptionalType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let wrapped: Type

    public init(_ w: Type) {
        wrapped = w
    }
}

public class MetaType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let reference: Type

    public init(_ r: Type) {
        reference = r
    }
}

public class MetaProtocol : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public var proto: Type!

    public init(_ p: Type) {
        proto = p
    }
}
