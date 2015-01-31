import Parser

public class Generator : ASTVisitor {
    var module: Module

    public init(moduleID: String) {
        module = Module(moduleID: moduleID)
    }

    public func visit(ast: TopLevelDeclaration) {
        /*
         * top_level_code function
         */
        var topLevelCodeType = FunctionType.get(
            Type.getVoidTy(module.getContext()),
            [],
            false
        )
        var topLevelCode = Function.create(
            topLevelCodeType,
            .InternalLinkage,
            "top_level_code",
            module
        )
        topLevelCode.setCallingConv(.C)
        var topLevelCodeBlock = BasicBlock.create(
            module.getContext(),
            "entry", 
            topLevelCode,
            nil
        )
        // return void
        ReturnInst.create(module.getContext(), topLevelCodeBlock)

        /*
         *  main function
         */
        var argcType = IntegerType.get(module.getContext(), 32)
        var argvType = PointerType.get(
            PointerType.get(
                IntegerType.get(module.getContext(), 8),
                .Generic
            ),
            .Generic
        )
        var mainType = FunctionType.get(
            IntegerType.get(module.getContext(), 32),
            [argcType, argvType],
            false
        )
        var main = Function.create(
            mainType,
            .ExternalLinkage,
            "main",
            module
        )
        main.setCallingConv(.C)
        var arg = main.argBegin()
        arg.setName("argc")
        arg.next()
        arg.setName("argv")
        var mainBlock = BasicBlock.create(module.getContext(), "entry", main, nil)
        // call top_level_code
        var call = CallInst.create(topLevelCode, [], "", mainBlock)
        // return 0
        var zero = ConstantInt.get(module.getContext(), APInt(numBits: 32, "0", 10))
        ReturnInst.create(module.getContext(), zero, mainBlock)
    }

    public func print(fileName: String) {
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
