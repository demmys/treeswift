import AST

extension TypeInference {
    public func visit(node: TypeInst) throws {}

    public func visit(node: ConstantInst) throws {}

    public func visit(node: VariableInst) throws {}

    public func visit(node: FunctionInst) throws {}

    public func visit(node: OperatorInst) throws {}

    public func visit(node: EnumInst) throws {}

    public func visit(node: EnumCaseInst) throws {}

    public func visit(node: StructInst) throws {}

    public func visit(node: ClassInst) throws {}

    public func visit(node: ProtocolInst) throws {}

    public func visit(node: TypeRef) throws {}

    public func visit(node: ValueRef) throws {}

    public func visit(node: OperatorRef) throws {}

    public func visit(node: EnumCaseRef) throws {}

    public func visit(node: ImplicitParameterRef) throws {}
}
