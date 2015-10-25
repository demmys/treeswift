public class Attribute {
    let attr: String

    public init(_ a: String) {
        attr = a
    }
}

public enum Modifier : String {
    case Convenience, Dynamic, Final, Lazy, Mutating, Nonmutating
    case Optional, Override, Required, Static, Weak
    case Unowned, UnownedSafe, UnownedUnsafe
    case Internal, InternalSet, Private, PrivateSet, Public, PublicSet
    case Class, Infix, Prefix, Postfix
}
