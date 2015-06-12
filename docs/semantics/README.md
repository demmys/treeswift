Semantics of TreeSwift
====

Below are the semantics of TreeSwift.  

These semantics only describe the procedures which are to produce LLVM-IR.  
In other words, the whole semantics of TreeSwift are defined as the sintactic sugar of LLVM-IR.  
To understand whole step of evaluation, you need to check out the [document of LLVM-IR](http://llvm.org/docs/LangRef.html).

## Context

Context will be given from parent scope and expected to be used as the context of child scope.

```swift
typealias Function = (String, type)

class Context {
    let parent: Context?
    var labelName: String?
    var breakLabel: Label?
    var continueLabel: Label?
    var stack: [LLVMValueRef] = []

    init(parent: Context? = nil, labelName: String? = nil) {
        self.parent = parent
        self.labelName = labelName
    }

    func findNamedBreakLabel(labelName: String) -> Label? {
        if labelName == labelname {
            return breakLabel
        }
        return parent?.findNamedBreakLabel(labelName)
    }

    func findNamedContinueLabel(labelName: String) -> Label? {
        if labelName == labelname {
            return continueLabel
        }
        return parent?.findNamedBreakLabel(labelName)
    }

    func findPrefixOperatorFunction(operator: String) -> Function? {}

    func findBinaryOperatorFunction(operator: String) -> Function? {}

    func findPostfixOperatorFunction(operator: String) -> Function? {}

    func isGlobal() -> Bool {
        return parent == nil
    }

    func getGlobal() -> Context {
        if let p = parent {
            return p.getGlobal()
        }
        return self
    }

    func push(v: LLVMValue) {}

    func pop() -> LLVMValue? {}
}
var c: Context?
```

## Evaluation rules

* [Top level declaration and Statements](top_level_declaration_and_statements.md)
* [Loop statement](loop_statement.md)
* [Branch statement](branch_statement.md)
* [Labeled statement and Control transfer statement](labeled_statement_and_control_transfer_statement.md)
* [Declarations](declarations.md)
* [Constant declaration, Variable declaration](constant_declaration_variable_declaration.md)
* Type alias declaration
* [Function declaration](function_declaration.md)
* [Operator declaration](operator_declaration.md)
* Patterns
* Types
* Expressions
* Literals

## Typing rules
