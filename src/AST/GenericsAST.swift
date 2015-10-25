public class GenericParameterClause {
    public var params: [GenericParameter] = []
    public var reqs: [Requirement] = []

    public init() {}
}

public enum GenericParameter {
    case Identifier(TypeRef)
    case Conformance(TypeRef, IdentifierType)
    case ProtocolConformance(TypeRef, ProtocolCompositionType)
}

public enum Requirement {
    case Conformance(IdentifierType, IdentifierType)
    case ProtocolConformance(IdentifierType, ProtocolCompositionType)
    case SameType(IdentifierType, Type)
}
