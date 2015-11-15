import AST

extension TypeInference {
    public func visit(node: IdentityPattern) throws {}

    public func visit(node: BooleanPattern) throws {
        node.type.fixType(try boolType())
    }

    public func visit(node: ConstantIdentifierPattern) throws {
        addConstraint(node, node.inst)
    }

    public func visit(node: VariableIdentifierPattern) throws {
        addConstraint(node, node.inst)
    }

    public func visit(node: ReferenceIdentifierPattern) throws {
        addConstraint(node, node.ref)
    }

    public func visit(node: WildcardPattern) throws {}

    private func typeOfPatternTuple(tuple: PatternTuple) -> TupleType {
        let xs = TupleType()
        for (label, pat) in tuple {
            xs.elems.append(TupleTypeElement(label, pat))
        }
        return xs
    }

    public func visit(node: TuplePattern) throws {
        addConstraint(node, typeOfPatternTuple(node.tuple))
        for (_, pat) in node.tuple {
            try pat.accept(self)
        }
    }

    public func visit(node: VariableBindingPattern) throws {
        addConstraint(node, node.pat)
        try node.pat.accept(self)
    }

    public func visit(node: ConstantBindingPattern) throws {
        addConstraint(node, node.pat)
        try node.pat.accept(self)
    }

    public func visit(node: OptionalPattern) throws {
        addConstraint(node, OptionalType(node.pat))
        try node.pat.accept(self)
    }

    public func visit(node: TypeCastingPattern) throws {
        try node.pat.accept(self)
    }

    public func visit(node: EnumCasePattern) throws {
        assert(false, "Enum case pattern is not implemented.")
    }

    public func visit(node: TypePattern) throws {}

    public func visit(node: ExpressionPattern) throws {
        try node.exp.accept(self)
    }
}
