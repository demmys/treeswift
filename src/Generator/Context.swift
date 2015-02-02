import Parser

private class TypeContext {
    private let module: Module
    private lazy var reference: [String:LLVMType] = [
        "Void": LLVMType.getVoidTy(self.module.getContext()),
        "Int": IntegerType.get(self.module.getContext(), 32),
        "Bool": IntegerType.get(self.module.getContext(), 1)
    ]

    init(module: Module) {
        self.module = module
    }

    func get(type: Type) -> LLVMType? {
        switch type {
        case let .Single(name):
            return reference[name]
        case let .Tuple(tt):
            return nil
        case let .Function(ft):
            return nil
        case let .Array(at):
            return nil
        }
    }
}

private class VariableContext {
    private let module: Module
    private unowned let parent: Context
    private var reference: [String:Value] = [:]

    init(module: Module, parent: Context) {
        self.module = module
        self.parent = parent
    }

    func get(name: String) -> Value? {
        return reference[name]
    }

    func create(name: String, type: Type) -> Value? {
        if get(name) != nil {
            return nil
        }
        if let t = parent.getType(type) {
            let pointer = parent.addInst(.Alloca(name, t))
            reference[name] = pointer
            return pointer
        }
        return nil
    }
}

private class OperatorContext {
    private let module: Module
    private lazy var prefixReference: [String:Operator] = [
        "+": PrefixPositive(),
        "-": PrefixNegative(),
        "++": PrefixIncrement(),
        "--": PrefixDecrement()
    ]
    private lazy var postfixReference: [String:Operator] = [
        "++": PostfixIncrement(),
        "--": PostfixDecrement()
    ]
    private lazy var binaryReference: [String:Operator] = [
        "+": InfixAdd(),
        "-": InfixSub(),
        "*": InfixMul(),
        "/": InfixDiv(),
        "<": InfixLessThan(),
        ">": InfixGreaterThan(),
        "+=": InfixAddAssign(),
        "-=": InfixSubAssign(),
        "*=": InfixMulAssign(),
        "/=": InfixDivAssign()
    ]

    init(module: Module) {
        self.module = module
    }

    func getPrefix(name: String) -> Operator? {
        return prefixReference[name]
    }

    func getPostfix(name: String) -> Operator? {
        return postfixReference[name]
    }

    func getInfix(name: String) -> Operator? {
        return binaryReference[name]
    }
}

private class FunctionContext {
    private let module: Module
    private unowned let parent: Context
    private var reference: [String:Function] = [:]


    init(module: Module, parent: Context) {
        self.module = module
        self.parent = parent
    }

    func get(name: String) -> Function? {
        return reference[name]
    }

    func create(name: String, params: [Parameter], ret: Type) -> Context? {
        if get(name) != nil {
            return nil
        }
        if let rt = parent.getType(ret) {
            var paramType: [LLVMType] = []
            for param in params {
                if let pt = parent.getType(param.type) {
                    paramType.append(pt)
                } else {
                    return nil
                }
            }
            let type = FunctionType.get(rt, paramType, false)
            let function = Function.create(type, .ExternalLinkage, name, module)
            function.setCallingConv(.C)
            let block = BasicBlock.create(module.getContext(), "entry", function, nil)
            let context = Context(module: module,
                                  block: block,
                                  parent: parent,
                                  function: function)

            var it = function.argBegin()
            for param in params {
                let argName = param.localName! + "_arg"
                it.setName(argName)
                let arg = context.createVariable(param.localName!, param.type)
                let table = function.getValueSymbolTable()
                context.addInst(.Store(table.lookup(argName), arg!))
                it.next()
            }

            reference[name] = function
            return context
        }
        return nil
    }
}

enum Instruction {
    case Alloca(String, LLVMType)
    case Store(Value, Value)
    case Load(Value, String)
    case Call(Function, [Value])
    case Return(Value?)
}

class Context {
    let builder: IRBuilder
    private let module: Module
    var function: Function?
    var block: BasicBlock?
    private var parent: Context?
    private var types: TypeContext
    private var vars: VariableContext!
    private var ops: OperatorContext
    private var funcs: FunctionContext!
    private var temporaryName: Int = 0
    var temporaryValue: Value?

    init(module: Module,
         block: BasicBlock? = nil,
         parent: Context? = nil,
         function: Function? = nil) {
        self.module = module
        self.builder = IRBuilder(c: module.getContext())
        self.block = block
        self.parent = parent
        self.function = function
        types = TypeContext(module: module)
        ops = OperatorContext(module: module)
        vars = VariableContext(module: module, parent: self)
        funcs = FunctionContext(module: module, parent: self)
    }

    /*
     * type
     */
    func getType(type: Type) -> LLVMType? {
        if let t = types.get(type) {
            return t
        } else {
            return parent?.getType(type)
        }
    }
    func getType(type: String) -> LLVMType? {
        return getType(Type.Single(type))
    }

    /*
     * variable
     */
    func getVariablePointer(name: String) -> Value? {
        if let v = vars.get(name) {
            return v
        } else {
            return parent?.getVariablePointer(name)
        }
    }

    func createVariable(name: String, _ type: Type) -> Value? {
        return vars.create(name, type: type)
    }

    /*
     * operator
     */
    func getPrefixOperator(name: String) -> Operator? {
        if let o = ops.getPrefix(name) {
            return o
        } else {
            return parent?.getPrefixOperator(name)
        }
    }

    func getPostfixOperator(name: String) -> Operator? {
        if let o = ops.getPostfix(name) {
            return o
        } else {
            return parent?.getPostfixOperator(name)
        }
    }

    func getInfixOperator(name: String) -> Operator? {
        if let o = ops.getInfix(name) {
            return o
        } else {
            return parent?.getInfixOperator(name)
        }
    }

    /*
     * function
     */
    func getFunction(name: String) -> Function? {
        if let f = funcs.get(name) {
            return f
        } else {
            return parent?.getFunction(name)
        }
    }

    func createFunction(name: String, _ clauses: [ParameterClause], _ ret: Type?)
        -> Context? {
        var params: [Parameter] = []
        for clause in clauses {
            if let ps = clause.value {
                params.extend(ps)
            }
        }
        return funcs.create(name, params: params, ret: ret ?? Type.Single("Void"))
    }
    func createFunction(name: String, _ clauses: [ParameterClause], _ ret: String)
        -> Context? {
        return createFunction(name, clauses, Type.Single(ret))
    }


    /*
     * instruction
     */
    func addInst(inst: Instruction) -> LLVMInstruction {
        switch inst {
        case let .Alloca(name, type):
            return AllocaInst(type: type, getConstantInt(32, value: 0), name, block)
        case let .Store(value, pointer):
            return StoreInst(val: value, pointer, block)
        case let .Load(pointer, name):
            return LoadInst(value: pointer, name, block)
        case let .Call(function, params):
            return CallInst.create(function, params, "", block)
        case let .Return(value):
            if let v = value {
                return ReturnInst.create(module.getContext(), v, block)
            } else {
                return ReturnInst.create(module.getContext(), block)
            }
        }
    }

    /*
     * helpers
     */
    func getConstantInt(bits: UInt32, value: Int) -> ConstantInt {
        return ConstantInt.get(
            module.getContext(),
            APInt(numBits: bits, String(value), 10)
        )
    }

    func getValueSymbolTable() -> ValueSymbolTable? {
        return block?.getValueSymbolTable()
    }

    func getTemporaryName() -> String {
        return "_\(temporaryName++)"
    }
}
