public class GenericParameterClause {
    public var params: [GenericParameter] = []
    public var reqs: [Requirement] = []

    public init() {}
}

public enum GenericParameter {
    case Identifier(TypeInst)
    case Conformance(TypeInst, IdentifierType)
    case ProtocolConformance(TypeInst, ProtocolCompositionType)
}

public enum Requirement {
    case Conformance(IdentifierType, IdentifierType)
    case ProtocolConformance(IdentifierType, ProtocolCompositionType)
    case SameType(IdentifierType, Type)
}
