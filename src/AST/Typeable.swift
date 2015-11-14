public protocol Typeable {
    var type: TypeCandidate { get }
}

public class TypeCandidate {
    private var candidates: [Type] = []
    private var candidateGenerators: [() -> TypeCandidate] = []

    public init() {}

    public func addCandidate(type: Type) {
        candidates.append(type)
    }
    public func addCandidate(generator: () -> TypeCandidate) {
        candidateGenerators.append(generator)
    }
}
