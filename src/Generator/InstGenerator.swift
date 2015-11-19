import AST
import LLVM

extension Generator {
    public func visit(node: TypeInst) throws {}

    public func visit(node: ConstantInst) throws {}

    public func visit(node: VariableInst) throws {
        // TODO
    }

    public func visit(node: FunctionInst) throws {
        if let value = node.llvmValue {
            valueStack.append(value)
        }
        guard case let (functionType as FunctionType)? = node.type.type else {
            assert(false, "function has not a function type")
        }
        let argsElems = elementsOfArgs(functionType.arg)
        let retElems = elementsOfType(functionType.ret)
        let name = serializeFunctionName(
            currentNameElements, argsElems: argsElems, retElems: retElems
        )
        let value = declareFunction(
            module, name, llvmTypeOfArgs(functionType.arg),
            llvmTypeOfType(functionType.ret)
        )
        node.llvmValue = value
        valueStack.append(value)
    }

    func elementsOfType(type: Typeable) -> [NameStructureElement] {
        return []
    }

    func elementsOfArgs(type: Typeable) -> [[NameStructureElement]] {
        return []
    }

    func llvmTypeOfArgs(type: Typeable) -> [LLVMTypeRef] {
        return []
    }

    func llvmTypeOfType(type: Typeable) -> LLVMTypeRef {
        return LLVMVoidType()
    }

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
