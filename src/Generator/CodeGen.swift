import Parser

public class Generator : ASTVisitor {
    private let module: Module
    private let global: Context
    private var local: Context

    public init(moduleID: String) {
        module = Module(moduleID: moduleID)
        global = Context(module: module)
        local = global
    }

    public func visit(literalExpression: LiteralExpression) {
        switch literalExpression {
        case let .Integer(v):
            local.temporaryValue = global.getConstantInt(32, value: v)
        case let .Array(exps):
            break
        case .True:
            local.temporaryValue = global.getConstantInt(1, value: 1)
        case .False:
            local.temporaryValue = global.getConstantInt(1, value: 0)
        case .Nil:
            break
        }
    }

    public func visit(prefixExpression: PrefixExpression) {
        switch prefixExpression.head {
        case let .Reference(name):
            if let p = local.getVariablePointer(name) {
                local.temporaryValue = local.addInst(
                    .Load(p, local.getTemporaryName())
                )
                if let op = prefixExpression.op {
                    local.temporaryValue = local.getPrefixOperator(op)?.apply(
                        local,
                        x: local.temporaryValue!
                    )
                }
                if let tail = prefixExpression.tail {
                    switch tail[0] {
                    case let .PostfixOperation(op):
                        local.temporaryValue = local.getPostfixOperator(op)?.apply(
                            local,
                            x: local.temporaryValue!
                        )
                    default:
                        break
                    }
                }
            } else if let f = local.getFunction(name) {
                if let tail = prefixExpression.tail {
                    switch tail[0] {
                    case let .FunctionCall(expels, _):
                        var params: [Value] = []
                        for expel in expels {
                            switch expel {
                            case let .Unnamed(exp):
                                exp.accept(self)
                            case let .Named(name, exp):
                                exp.accept(self)
                            }
                            params.append(local.temporaryValue!)
                        }
                        local.temporaryValue = local.addInst(.Call(f, params))
                    default:
                        break
                    }
                }
            }
        case let .Value(lit):
            lit.accept(self)
        case let .Closure(cls):
            break
        case let .Parenthesized(elems):
            break
        case let .Whildcard:
            break
        }
    }

    public func visit(expression: Expression) {
        switch expression {
        case let .InOut(id):
            break
        case let .Term(pre, bins):
            pre.accept(self)
            if let bs = bins {
                switch bs[0] {
                case let .BinaryOperation(op, pre):
                    let a = local.temporaryValue!
                    pre.accept(self)
                    let b = local.temporaryValue!
                    local.temporaryValue = local.getInfixOperator(op)?.apply(
                        local,
                        a: a,
                        b: b
                    )
                case let .AssignmentOperation(pre):
                    break
                default:
                    break
                }
            }
        }
    }

    public func visit(declaration: Declaration) {
        switch declaration {
        case let .Constant(inits):
            break
        case let .Variable(inits):
            for ini in inits {
                switch ini.pattern {
                case let .Wildcard(type):
                    break
                case let .Variable(name, type):
                    if let p = local.createVariable(name, type!) {
                        if let exp = ini.initializer {
                            exp.accept(self)
                            local.addInst(.Store(local.temporaryValue!, p))
                        }
                    }
                case let .ValueBinding(bind):
                    break
                case let .Tuple(pats, type):
                    break
                }
            }
        case let .Typealias(name, ty):
            break
        case let .Function(name, clauses, ret, statements):
            local = global.createFunction(name, clauses, ret)!
            if let stms = statements {
                for stm in stms {
                    stm.accept(self)
                }
            }
        case let .OperatorFunction(name, clauses, ty, stms):
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
            switch cond {
            case let .Term(exp):
                exp.accept(self)
            }
            var mergeBlock = BasicBlock.create(module.getContext(), "merge",
                                               local.function, nil)
            var elseBlock = BasicBlock.create(module.getContext(), "else",
                                              local.function, mergeBlock)
            var thenBlock = BasicBlock.create(module.getContext(), "then",
                                              local.function, elseBlock)
            local.builder.setInsertPoint(local.block)
            local.builder.createCondBr(local.temporaryValue!, thenBlock, elseBlock)
            local.block = thenBlock
            if let ss = stms {
                for s in ss {
                    s.accept(self)
                }
            }
            local.builder.setInsertPoint(thenBlock)
            local.builder.createBr(mergeBlock)
            local.builder.setInsertPoint(elseBlock)
            local.builder.createBr(mergeBlock)
            local.block = mergeBlock
        case let .Break(id):
            break
        case let .Continue(id):
            break
        case let .Return(exp):
            if let e = exp {
                e.accept(self)
                local.addInst(.Return(local.temporaryValue))
            } else {
                local.addInst(.Return(nil))
            }
        }
    }

    public func visit(topLevelDeclaration: TopLevelDeclaration) {
        let tlc = "top_level_code"
        if let ctx = local.createFunction(tlc, [], "Void") {
            if let ctx = local.createFunction("main", [], "Int") {
                ctx.addInst(.Call(local.getFunction(tlc)!, []))
                ctx.addInst(.Return(global.getConstantInt(32, value: 0)))
            }
            if let statements = topLevelDeclaration.value {
                for statement in statements {
                    local = ctx
                    statement.accept(self)
                }
            }
            ctx.addInst(.Return(nil))
        }
    }

    public func print(fileName: String) {
        var err = UnsafePointer<CChar>()
        var os = RawFDOStream(fileName: fileName, &err, .None)

        if let e = String.fromCString(err) {
            os.close()
            return
        }

        var pm = PassManager()
        pm.add(ModulePass.createPrintModulePass(os, ""))
        pm.run(module)

        os.close()
    }
}
