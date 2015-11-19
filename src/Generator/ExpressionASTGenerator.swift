import AST

extension Generator {
    public func visit(node: Expression) throws {}

    public func visit(node: ExpressionBody) throws {}

    public func visit(node: BinaryExpressionBody) throws {}

    public func visit(node: ConditionalExpressionBody) throws {}

    public func visit(node: TypeCastingExpressionBody) throws {}

    public func visit(node: PrefixedExpression) throws {}

    public func visit(node: PostfixedExpression) throws {}

    public func visit(node: ExpressionCore) throws {}
}
