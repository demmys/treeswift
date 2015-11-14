public protocol Typeable {
    var type: TypeCandidate { get }
}

public class TypeCandidate {
    private var candidates: [Type] = []
    private var candidateGenerators: [() -> TypeCandidate] = []
    private var subtypes: [IdentifierType] = []

    public init() {}

    public func addCandidate(type: Type) {
        candidates.append(type)
    }
    public func addCandidate(generator: () -> TypeCandidate) {
        candidateGenerators.append(generator)
    }

    public func addSubtype(type: IdentifierType) {
        subtypes.append(type)
    }
}
