import AST

public class TypeInference : ASTVisitor {
    private var constraints: [(Typeable, Typeable)] = []
    public init() {}

    func addConstraint(x: Typeable, _ y: Typeable) {
        constraints.append((x, y))
    }
}
