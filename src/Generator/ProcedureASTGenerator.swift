import AST
import LLVM

extension Generator {
    public func visit(node: FlowSwitch) throws {}

    public func visit(node: ForFlow) throws {}

    public func visit(node: ForInFlow) throws {}

    public func visit(node: WhileFlow) throws {}

    public func visit(node: RepeatWhileFlow) throws {}

    public func visit(node: IfFlow) throws {
        let thenBlock = LLVMInsertBasicBlock(builder.getInsertBlock(), "")
        let elseBlock = LLVMInsertBasicBlock(thenBlock, "")
        visitFlow(node, thenBlock: thenBlock, elseBlock: elseBlock)
        builder.positionAtEnd(thenBlock)
        for p in node.block {
            try p.accept(self)
        }
        if let els = node.els {
            guard case let .Else(ps) = els else {
                assert(false, "else if is not implemented")
            }
            let mergeBlock = LLVMInsertBasicBlock(elseBlock, "")
            builder.buildBr(mergeBlock)
            builder.positionAtEnd(elseBlock)
            for p in ps {
                try p.accept(self)
            }
            builder.buildBr(mergeBlock)
        } else {
            builder.buildBr(elseBlock)
        }
    }

    public func visit(node: GuardFlow) throws {}

    public func visit(node: DeferFlow) throws {}

    public func visit(node: DoFlow) throws {}

    public func visit(node: CatchFlow) throws {}

    public func visit(node: CaseFlow) throws {}

    private func visitFlow(
        node: Flow, thenBlock: LLVMBasicBlockRef, elseBlock: LLVMBasicBlockRef
    ) throws {
        visitPatternMatching(node.pats[0]) // valueStack <= Builtin.Int1
        builder.buildCondBr(
            valueStack.popLast()!, thenBlock: thenBlock, elseBlock: elseBlock
        )
    }

    private func visitPatternMatching(node: PatternMatching) {
        /*
        switch node.pat {
        case is IdentityPattern:
            valueStack.append(LLVMConstInt(LLVMInt1Type(), 1, LLVMBoolTrue))
        case is BooleanPattern:
            try node.exp!.accept(self) // valueStack <= Bool
            let boolType = node.exp!.type.type!
            guard let unwrapper = boolType.memberValues["_builtinBooleanLiteral"] else {
                throw ErrorReporter.instance.fatal(.TypeNotCompatibleWithBooleanLiteral(boolType.name), nil)
            }
            try unwrapper.accept(self) // valueStack <= Bool -> Builtin.Int1
            valueStack.append(
                builder.buildCall(valueStack.popLast()!, valueStack.popLast()!)
            )
        default:
            assert(false, "Pattern matching but IdentityPattern and BooleanPattern is not implemented")
        }
        */
    }

    public func visit(node: Operation) throws {
        switch node {
        case let .ExpressionOperation(exp):
            try exp.accept(self)
        case .AssignmentOperation:
            assert(false, "Assignment operation is not implemented.")
        case .BreakOperation:
            assert(false, "Break operation is not implemented.")
        case .ContinueOperation:
            assert(false, "Continue operation is not implemented.")
        case .FallthroughOperation:
            assert(false, "Fallthrough operation is not implemented.")
        case let .ReturnOperation(v):
            try exp.accept(self)
            builder.buildRet(valueStack.popLast()!)
        case .ThrowOperation:
            assert(false, "Throw operation is not implemented.")
        }
    }
}
