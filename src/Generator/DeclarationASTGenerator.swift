import AST
import LLVM

extension Generator {
    public func visit(node: Module) throws {}

    public func visit(node: TopLevelDeclaration) throws {
        if node.isMain {
            mainFunction = declareFunction(module, "main", [
                LLVMInt32Type(),
                LLVMPointerType(
                    LLVMPointerType(
                        LLVMInt8Type(), AddressSpace.ADDRESS_SPACE_GENERIC.rawValue
                    ),
                    LLVM.AddressSpace.ADDRESS_SPACE_GENERIC.rawValue
                )
            ], LLVMInt32Type())
            builder.positionAtEnd(LLVMAppendBasicBlock(mainFunction!, "entry"))
        }
        for p in node.procedures {
            try p.accept(self)
        }
        if node.isMain {
            builder.buildRet(LLVMConstInt(LLVMInt32Type(), 0, LLVMBoolTrue))
        }
    }

    public func visit(node: ImportDeclaration) throws {}

    public func visit(node: PatternInitializerDeclaration) throws {}

    public func visit(node: VariableBlockDeclaration) throws {}

    public func visit(node: VariableBlock) throws {}

    public func visit(node: TypealiasDeclaration) throws {}

    public func visit(node: FunctionDeclaration) throws {
        switch node.name! {
        case let .Function(i):
            currentNameElements.append(.Function(i.name))
            try i.accept(self)
        case let .Operator(_, i):
            currentNameElements.append(.Operator(i.name))
            try i.accept(self)
        }
        let function = valueStack.popLast()!
        if node.body.count > 0 {
            let entryBlock = LLVMAppendBasicBlock(function, "entry")
            builder.positionAtEnd(entryBlock)
            for p in node.body {
                try p.accept(self)
            }
        }
        currentNameElements.removeLast()
    }

    public func visit(node: EnumDeclaration) throws {}

    public func visit(node: StructDeclaration) throws {}

    public func visit(node: ClassDeclaration) throws {}

    public func visit(node: ProtocolDeclaration) throws {}

    public func visit(node: InitializerDeclaration) throws {}

    public func visit(node: DeinitializerDeclaration) throws {}

    public func visit(node: ExtensionDeclaration) throws {}

    public func visit(node: SubscriptDeclaration) throws {}

    public func visit(node: OperatorDeclaration) throws {}
}
