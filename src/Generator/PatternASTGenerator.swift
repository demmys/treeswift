import AST

extension Generator {
    public func visit(node: IdentityPattern) throws {}

    public func visit(node: BooleanPattern) throws {}

    public func visit(node: ConstantIdentifierPattern) throws {}

    public func visit(node: VariableIdentifierPattern) throws {}

    public func visit(node: ReferenceIdentifierPattern) throws {}

    public func visit(node: WildcardPattern) throws {}

    public func visit(node: TuplePattern) throws {}

    public func visit(node: VariableBindingPattern) throws {}

    public func visit(node: ConstantBindingPattern) throws {}

    public func visit(node: OptionalPattern) throws {}

    public func visit(node: TypeCastingPattern) throws {}

    public func visit(node: EnumCasePattern) throws {}

    public func visit(node: TypePattern) throws {}

    public func visit(node: ExpressionPattern) throws {}
}
