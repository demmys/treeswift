public class LLVMModule {
    let raw: LLVMModuleRef

    public init(name: String) {
        raw = LLVMModuleCreateWithName(name)
    }

    deinit {
        LLVMDisposeModule(raw)
    }

    public func addFunction(name: String, _ functionType: LLVMTypeRef) -> LLVMValueRef {
        return LLVMAddFunction(raw, name, functionType)
    }

    public func getNamedFunction(name: String) -> LLVMValueRef? {
        let function = LLVMGetNamedFunction(raw, name)
        if function == COpaquePointer(nilLiteral: ()) {
            return nil
        }
        return function
    }

    public func dump() {
        LLVMDumpModule(raw)
    }

    public func printToFile(fileName: String) -> Bool {
        let message = UnsafeMutablePointer<UnsafeMutablePointer<CChar>>()
        if LLVMPrintModuleToFile(raw, fileName, message) == LLVMBoolTrue {
            return true
        }
        return false
    }
}

public class LLVMBuilder {
    let raw: LLVMBuilderRef

    public init() {
        raw = LLVMCreateBuilder()
    }

    deinit {
        LLVMDisposeBuilder(raw)
    }

    public func positionAtEnd(block: LLVMBasicBlockRef) {
        LLVMPositionBuilderAtEnd(raw, block)
    }

    public func getInsertBlock() -> LLVMBasicBlockRef {
        return LLVMGetInsertBlock(raw)
    }

    public func buildCall(
        function: LLVMValueRef, args: [LLVMValueRef]
    ) -> LLVMValueRef {
        let argsPointer = MutableArrayPointer<LLVMValueRef>(args)
        return LLVMBuildCall(raw, function, argsPointer.pointer, argsPointer.count, "")
    }

    public func buildBr(destBlock: LLVMBasicBlockRef) {
        LLVMBuildBr(raw, destBlock)
    }

    public func buildCondBr(
        cond: LLVMValueRef, thenBlock: LLVMBasicBlockRef, elseBlock: LLVMBasicBlockRef
    ) {
        LLVMBuildCondBr(raw, cond, thenBlock, elseBlock)
    }

    public func buildPhi(
        type: LLVMTypeRef, incomings: [LLVMValueRef:LLVMBasicBlockRef]
    ) -> LLVMValueRef {
        let phi = LLVMBuildPhi(raw, type, "")
        let values = MutableArrayPointer<LLVMValueRef>(Array(incomings.keys))
        let blocks = MutableArrayPointer<LLVMBasicBlockRef>(Array(incomings.values))
        LLVMAddIncoming(phi, values.pointer, blocks.pointer, values.count)
        return phi
    }

    public func buildRet(value: LLVMValueRef) {
        LLVMBuildRet(raw, value)
    }
}

public class LLVMStruct {
    let raw: LLVMTypeRef
    public var type: LLVMTypeRef { return raw }

    public init(
        name: String, elementTypes: MutableArrayPointer<LLVMTypeRef>, packed: LLVMBool
    ) {
        raw = LLVMStructCreateNamed(LLVMGetGlobalContext(), name)
        LLVMStructSetBody(raw, elementTypes.pointer, elementTypes.count, packed)
    }
}

public class MutableArrayPointer<Element> {
    public typealias Pointer = UnsafeMutablePointer<Element>
    let size: Int
    let p: Pointer

    public var pointer: Pointer { return p }
    public var count: UInt32 { return UInt32(size) }

    public init(_ array: [Element]) {
        size = array.count
        p = Pointer.alloc(size)
        p.initializeFrom(array)
    }

    deinit {
        p.dealloc(size)
    }
}

public let LLVMBoolTrue: Int32 = 1
public let LLVMBoolFalse: Int32 = 0

public enum AddressSpace : UInt32 {
    case ADDRESS_SPACE_GENERIC = 0
    case ADDRESS_SPACE_GLOBAL = 1
    case ADDRESS_SPACE_SHARED = 3
    case ADDRESS_SPACE_CONST = 4
    case ADDRESS_SPACE_LOCAL = 5

    // NVVM Internal
    case ADDRESS_SPACE_PARAM = 101
}
