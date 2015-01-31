import Parser

public class Generator {
    public class func generate(ast: AST, moduleID: String) -> Module {
        var module = Module(moduleID: moduleID)

        var zero = ConstantInt.get(module.getContext(), APInt(numBits: 32, "0", 10))

        /*
         *  global variable
         */
        var msg = GlobalVariable(
            module: module,
            ArrayType.get(IntegerType.get(module.getContext(), 8), 14),
            true,
            .PrivateLinkage,
            ConstantDataArray.getString(module.getContext(), "Hello, World!", true),
            "msg",
            nil,
            .NotThreadLocal,
            .Generic,
            false
        )

        /*
         *  main function
         */
        var mainType = FunctionType.get(
            IntegerType.get(module.getContext(), 32),
            [],
            false
        )
        var main = Function.create(
            mainType,
            .ExternalLinkage,
            "main",
            module
        )
        main.setCallingConv(.C)
        var main_block = BasicBlock.create(module.getContext(), "entry", main, nil)

        // call puts
        var putsType = FunctionType.get(
            IntegerType.get(module.getContext(), 32),
            [PointerType.get(IntegerType.get(module.getContext(), 8), .Generic)],
            false
        )
        var puts = Function.create(
            putsType,
            .ExternalLinkage,
            "puts",
            module
        )
        puts.setCallingConv(.C)

        var msg_ptr = ConstantExpr.getGetElementPtr(msg, [zero, zero], true)

        var call = CallInst.create(puts, [msg_ptr], "", main_block)

        // return 0
        ReturnInst.create(module.getContext(), zero, main_block)

        return module
    }

    public class func print(module: Module, fileName: String) {
        var err = UnsafePointer<CChar>()
        var os = RawFDOStream(fileName: fileName, &err, .None)

        if let e = String.fromCString(err) {
            println(e)
            os.close()
            return
        }

        var pm = PassManager()
        pm.add(ModulePass.createPrintModulePass(os, ""))
        pm.run(module)

        os.close()
    }
}
