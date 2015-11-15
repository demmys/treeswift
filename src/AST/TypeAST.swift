public class Type : Typeable {
    public var type: TypeManager

    public init () {
        type = TypeManager()
        type.fixType(self)
    }

    public func stringify() -> String {
        return "<<error type>>"
    }
}

public typealias TypeAnnotation = (Type, attrs: [Attribute])

public class IdentifierType : Type {
    public let ref: TypeRef
    public let genArgs: [Type]?

    public init(_ r: TypeRef) {
        ref = r
        genArgs = nil
        super.init()
    }
    public init(_ r: TypeRef, _ g: [Type]?) {
        ref = r
        genArgs = g
        super.init()
    }

    public override func stringify() -> String {
        return ref.id.description
    }
}

public class ArrayType : Type {
    public let elem: Typeable

    public init(_ e: Typeable) {
        elem = e
        super.init()
    }

    public override func stringify() -> String {
        return "[\(elem.type.stringify())]"
    }
}

public class DictionaryType : Type {
    public let key: Typeable
    public let value: Typeable

    public init(_ k: Typeable, _ v: Typeable) {
        key = k
        value = v
        super.init()
    }

    public override func stringify() -> String {
        return "[\(key.type.stringify()):\(value.type.stringify())]"
    }
}

public class TupleType : Type {
    public var elems: [TupleTypeElement] = []

    public override init() {}
    public init(_ es: [TupleTypeElement]) {
        elems = es
        super.init()
    }

    public override func stringify() -> String {
        var presentation = "("
        for (i, elem) in elems.enumerate() {
            presentation += elem.type.type.stringify()
            if i == elems.count - 1 {
                break
            }
            presentation += ", "
        }
        return presentation + ")"
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
    public var types: [IdentifierType] = []

    public override func stringify() -> String {
        var presentation = "protocol<"
        for (i, type) in types.enumerate() {
            presentation += type.stringify()
            if i == types.count - 1 {
                break
            }
            presentation += ", "
        }
        return presentation + ">"
    }
}

public class FunctionType : Type {
    public let arg: Typeable
    public let throwType: ThrowType
    public let ret: Typeable

    public init(_ a: Typeable, _ t: ThrowType, _ r: Typeable) {
        arg = a
        throwType = t
        ret = r
        super.init()
    }

    public override func stringify() -> String {
        return "\(arg.type.stringify()) -> \(ret.type.stringify())"
    }
}

public class OptionalType : Type {
    public let wrapped: Typeable

    public init(_ w: Typeable) {
        wrapped = w
        super.init()
    }

    public override func stringify() -> String {
        return "\(wrapped.type.stringify())?"
    }
}

public class ImplicitlyUnwrappedOptionalType : Type {
    public let wrapped: Typeable

    public init(_ w: Typeable) {
        wrapped = w
        super.init()
    }

    public override func stringify() -> String {
        return "\(wrapped.type.stringify())!"
    }
}

public class MetaType : Type {
    public let reference: Typeable

    public init(_ r: Typeable) {
        reference = r
        super.init()
    }

    public override func stringify() -> String {
        return "\(reference.type.stringify()).TYPE"
    }
}

public class MetaProtocol : Type {
    public var proto: Typeable!

    public init(_ p: Typeable) {
        proto = p
        super.init()
    }

    public override func stringify() -> String {
        return "\(proto.type.stringify()).PROTOCOL"
    }
}
