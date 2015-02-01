import Parser

class TypeContext {
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

class VariableContext {
    private let module: Module

    init(module: Module) {
        self.module = module
    }
}

class FunctionContext {
    private let module: Module
    private let parent: Context
    private lazy var reference: [String:Function] = [:]


    init(module: Module, parent: Context) {
        self.module = module
        self.parent = parent
    }

    func get(name: String) -> Function? {
        return reference[name]
    }

    func create(name: String, params: [Parameter], ret: LLVMType) -> Context? {
        if get(name) != nil {
            return nil
        }
        var paramType: [LLVMType] = []
        for param in params {
            if let pt = parent.getType(param.type) {
                paramType.append(pt)
            } else {
                return nil
            }
        }
        var type = FunctionType.get(ret, paramType, false)
        var function = Function.create(type, .ExternalLinkage, name, module)
        function.setCallingConv(.C)
        reference[name] = function
        var block = BasicBlock.create(module.getContext(), "entry", function, nil)
        return Context(module: module, block: block, parent: parent)
    }
}

/*
class OperatorContext {
    private let module: Module
    private lazy var reference: [String:Function] = [
        "+": createAdd
    ]
}
*/

enum Instruction {
    case Call(String, [Value])
    case Return(Value?)
}

class Context {
    private let module: Module
    private var block: BasicBlock?
    private var parent: Context?
    private var types: TypeContext
    private var vars: VariableContext
    private var funcs: FunctionContext!

    init(module: Module, block: BasicBlock? = nil, parent: Context? = nil) {
        self.module = module
        self.block = block
        self.parent = parent
        types = TypeContext(module: module)
        vars = VariableContext(module: module)
        funcs = FunctionContext(module: module, parent: self)
    }

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

    func createVariable(name: String, type: Type) {
    }

    func getFunction(name: String) -> Function? {
        return funcs.get(name)
    }

    func createFunction(name: String, clauses: [ParameterClause], ret: String?)
        -> Context? {
        let typeName = ret ?? "Void"
        if let rt = getType(typeName) {
            var params: [Parameter] = []
            for clause in clauses {
                if let ps = clause.value {
                    params.extend(ps)
                }
            }
            return funcs.create(name, params: params, ret: rt)
        }
        return nil
    }

    func addInst(inst: Instruction) {
        switch inst {
        case let .Call(fstr, params):
            if let f = getFunction(fstr) {
                CallInst.create(f, params, "", block)
            }
        case let .Return(retval):
            if let v = retval {
                ReturnInst.create(module.getContext(), v, block)
            } else {
                ReturnInst.create(module.getContext(), block)
            }
        }
    }
}
