import AST

public class UnresolvedType : Typeable {
    public var type: Type?
}

public class TypeInference : ASTVisitor {
    private var constraints: [(Typeable, Typeable)] = []

    public init() {}

    func boolType() throws -> Type {
        return IdentifierType(try ScopeManager.createTypeRef("Bool", SourceInfo.PHANTOM))
    }

    func intType() throws -> Type {
        return IdentifierType(try ScopeManager.createTypeRef("Int", SourceInfo.PHANTOM))
    }

    func floatType() throws -> Type {
        return IdentifierType(try ScopeManager.createTypeRef("Float", SourceInfo.PHANTOM))
    }

    func stringType() throws -> Type {
        return IdentifierType(try ScopeManager.createTypeRef("String", SourceInfo.PHANTOM))
    }

    func addConstraint(x: Typeable, _ y: Typeable) {
        constraints.append((x, y))
    }
}
