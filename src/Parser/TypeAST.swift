public protocol Type : CustomStringConvertible {}

public class IdentifierType : Type {
    let ref: TypeRef
    let genArgs: [Type]?

    init(_ r: TypeRef, _ g: [Type]?) {
        ref = r
        genArgs = g
    }
}

public class ArrayType : Type {
    let elem: Type

    init(_ e: Type) {
        elem = e
    }
}

public class DictionaryType : Type {
    let key: Type
    let value: Type

    init(_ k: Type, _ v: Type) {
        key = k
        value = v
    }
}

public class TupleType : Type {
    var elems: [TupleTypeElement] = []
    var variadic: Bool = false
}

public class TupleTypeElement {
    var attrs: [Attribute] = []
    var inOut: Bool = false
    var label: String?
    var type: Type!
}

public class ProtocolCompositionType : Type {
    var types: [IdentifierType] = []
}

public class FunctionType : Type {
    let arg: Type
    let throwType: ThrowType
    let ret: Type

    init(_ a: Type, _ t: ThrowType, _ r: Type) {
        arg = a
        throwType = t
        ret = r
    }
}

public enum ThrowType {
    case Nothing, Throws, Rethrows
}

public class OptionalType : Type {
    let wrapped: Type

    init(_ w: Type) {
        wrapped = w
    }
}

public class ImplicitlyUnwrappedOptionalType : Type {
    let wrapped: Type

    init(_ w: Type) {
        wrapped = w
    }
}

public class MetaType : Type {
    let type: Type

    init(_ t: Type) {
        type = t
    }
}

public class MetaProtocol : Type {
    var proto: Type!

    init(_ p: Type) {
        proto = p
    }
}
