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
    public let nestedTypes: [(String, [Type]?)]

    public init(_ r: TypeRef) {
        ref = r
        genArgs = nil
        nestedTypes = []
    }
    public init(_ r: TypeRef, _ g: [Type]?, _ n: [(String, [Type]?)]) {
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
    public let elem: Typeable

    public init(_ e: Typeable) {
        elem = e
    }
}

public class DictionaryType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let key: Typeable
    public let value: Typeable

    public init(_ k: Typeable, _ v: Typeable) {
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
    public init(_ es: [TupleTypeElement]) {
        elems = es
    }
}

public class TupleTypeElement {
    public var attrs: [Attribute] = []
    public var inOut: Bool = false
    public var variadic: Bool = false
    public var label: String?
    public var type: Typeable!

    public init() {}
    public init(_ t: Typeable) {
        type = t
    }
    public init(_ l: String?, _ t: Typeable) {
        label = l
        type = t
    }
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
    public let arg: Typeable
    public let throwType: ThrowType
    public let ret: Typeable

    public init(_ a: Typeable, _ t: ThrowType, _ r: Typeable) {
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
    public let wrapped: Typeable

    public init(_ w: Typeable) {
        wrapped = w
    }
}

public class ImplicitlyUnwrappedOptionalType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let wrapped: Typeable

    public init(_ w: Typeable) {
        wrapped = w
    }
}

public class MetaType : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public let reference: Typeable

    public init(_ r: Typeable) {
        reference = r
    }
}

public class MetaProtocol : Type {
    public var type: Type? {
        get { return self }
        set {}
    }
    public var proto: Typeable!

    public init(_ p: Typeable) {
        proto = p
    }
}
