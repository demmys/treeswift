public class Attribute {
    let attr: String

    public init(_ a: String) {
        attr = a
    }
}

public enum Modifier {
    case Convenience, Dynamic, Final, Lazy, Mutating, Nonmutating
    case Optional, Override, Required, Static, Weak
    case Unowned, UnownedSafe, UnownedUnsafe
    case Class, Infix, Prefix, Postfix
    case AccessLevelModifier(AccessLevel)
}

public enum AccessLevel : String {
    case Internal, InternalSet, Private, PrivateSet, Public, PublicSet
}
