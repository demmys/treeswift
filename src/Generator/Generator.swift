import AST
import LLVM

public indirect enum NameStructureElement {
    case Module(String)
    case Struct(String)
    case Initializer
    case Function(String)
    case Typealias(String)
    case Label(String)
    case VariableGet(String)
    case Operator(String)
    case Tuple([[NameStructureElement]])
}

public class Generator : ASTVisitor {
    let moduleName: String
    let module: LLVMModule
    let builder: LLVMBuilder
    var mainFunction: LLVMValueRef?
    var blockStack: [LLVMBasicBlockRef] = []
    var valueStack: [LLVMValueRef] = []
    var currentNameElements: [NameStructureElement]

    public init(moduleName: String) {
        self.moduleName = moduleName
        module = LLVMModule(name: moduleName)
        builder = LLVMBuilder()
        currentNameElements = [.Module(moduleName)]
    }

    private func serializeNamePrefix(elems: [NameStructureElement]) -> String {
        var namePrefix = ""
        for elem in elems {
            switch elem {
            case .Module: namePrefix += "M"
            case .Struct: namePrefix += "S"
            case .Initializer: namePrefix += "I"
            case .Function: namePrefix += "F"
            case .Typealias: namePrefix += "T"
            case .Label: namePrefix += "L"
            case .VariableGet: namePrefix += "G"
            case .Operator: namePrefix += "O"
            case let .Tuple(elemsList):
                namePrefix += "tl"
                for elems in elemsList {
                    namePrefix += "_" + serializeNamePrefix(elems)
                }
                namePrefix += "tr"
            }
        }
        return namePrefix
    }

    private func serializeNameBody(elems: [NameStructureElement]) -> String {
        var nameBody = ""
        for elem in elems {
            switch elem {
            case let .Module(name):
                nameBody += "\(name.characters.count)\(name)"
            case let .Struct(name):
                nameBody += "\(name.characters.count)\(name)"
            case .Initializer:
                break
            case let .Function(name):
                nameBody += "\(name.characters.count)\(name)"
            case let .Typealias(name):
                nameBody += "\(name.characters.count)\(name)"
            case let .Label(name):
                nameBody += "\(name.characters.count)\(name)"
            case let .VariableGet(name):
                nameBody += "\(name.characters.count)\(name)"
            case let .Operator(name):
                nameBody += String(name.characters.count)
                for c in name.characters {
                    switch c {
                    case "+": nameBody += "a"
                    case "-": nameBody += "s"
                    case "<": nameBody += "l"
                    default: assert(false, "You cannot use '\(c)' in operator name now.")
                    }
                }
            case let .Tuple(elemsList):
                for elems in elemsList {
                    nameBody += "_" + serializeNameBody(elems)
                }
            }
        }
        return nameBody
    }

    func serializeTypeName(nameElems: [NameStructureElement]) -> String {
        return "_\(serializeNamePrefix(nameElems))\(serializeNameBody(nameElems))"
    }

    func serializeFunctionName(
        nameElems: [NameStructureElement], argsElems: [[NameStructureElement]],
        retElems: [NameStructureElement]
    ) -> String {
        let name = serializeNamePrefix(nameElems) + serializeNameBody(nameElems)
        var argsPrefix = ""
        var argsBody = ""
        for argElems in argsElems {
            if !argsPrefix.isEmpty {
                argsPrefix += "_"
                argsBody += "_"
            }
            argsPrefix += serializeNamePrefix(argElems)
            argsBody += serializeNameBody(argElems)
        }
        let ret = serializeNamePrefix(retElems) + serializeNameBody(retElems)
        return "_\(name)_\(argsPrefix)\(argsBody)_\(ret)"
    }

    func declareStruct(name: String, _ body: [LLVMTypeRef]) -> LLVMStruct {
        let structBodyType = MutableArrayPointer<LLVMTypeRef>(body)
        return LLVMStruct(name: name, elementTypes: structBodyType, packed: LLVMBoolTrue)
    }

    func declareFunction(
        module: LLVMModule, _ name: String, _ paramType: [LLVMTypeRef],
        _ retType: LLVMTypeRef
    ) -> LLVMValueRef {
        let paramType = MutableArrayPointer<LLVMTypeRef>(paramType)
        let functionType = LLVMFunctionType(
            retType, paramType.pointer, paramType.count, LLVMBoolFalse
        )
        return module.addFunction(name, functionType)
    }
}
