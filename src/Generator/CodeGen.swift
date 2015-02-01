import Parser

public class Generator : ASTVisitor {
    let module: Module
    let global: Context
    var local: Context

    public init(moduleID: String) {
        module = Module(moduleID: moduleID)
        global = Context(module: module)
        local = global
    }

    public func visit(expression: Expression) {
        switch expression {
        case let .InOut(id):
            break
        case let .Term(pre, bins):
            break
        }
    }

    public func visit(declaration: Declaration) {
        switch declaration {
        case let .Constant(inits):
            break
        case let .Variable(inits):
            break
        case let .Typealias(id, ty):
            break
        case let .Function(id, params, ty, stms):
            break
        case let .OperatorFunction(name, params, ty, stms):
            break
        case let .PrefixOperator(name):
            break
        case let .PostfixOperator(name):
            break
        case let .InfixOperator(name, pre, ass):
            break
        }
    }

    public func visit(statement: Statement) {
        switch statement {
        case let .Term(exp):
            exp.accept(self)
        case let .Definition(dec):
            dec.accept(self)
        case let .For(cond, stms, id):
            break
        case let .ForIn(pat, exp, stms, id):
            break
        case let .While(cond, stms, id):
            break
        case let .DoWhile(cond, stms, id):
            break
        case let .If(cond, stms, els):
            break
        case let .Break(id):
            break
        case let .Continue(id):
            break
        case let .Return(exp):
            break
        }
    }

    public func visit(topLevelDeclaration: TopLevelDeclaration) {
        let tlc = "top_level_code"
        if let ctx = local.createFunction(tlc, clauses: [], ret: nil) {
            if let ctx = local.createFunction("main", clauses: [], ret: "Int") {
                ctx.addInst(.Call(tlc, []))
                ctx.addInst(.Return(getConstantInt(32, value: 0)))
            }
            local = ctx
            ctx.addInst(.Return(nil))
        }
    }

    private func getConstantInt(bits: UInt32, value: Int) -> ConstantInt {
        return ConstantInt.get(
            module.getContext(),
            APInt(numBits: bits, String(value), 10)
        )
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
