### Function naming theories

* All LLVM functions (contains the currying functions) should have an another name.
* The LLVM function name only uses external parameter name.
* Swift functions can be curried with the void parameter.
* The Swift function with the same name can be declared only when these parameter types or parameter clause patterns are different. (Note that two Swift functions which contain the same parameter clause pattern can be declared, but it cannot be called with that pattern. Which causes "Ambiguous function name" error at the compile time.)
* So, we should declare LLVM functions with the full parametered name (even though it is for curring), and parameter clauses are separated with the "f" or "F" character. The character "F" represents that following clause is not considered in the declared LLVM function yet (function name represents that "When "f"ed clauses are given, it will return function with "F"ed clauses").

```swift
typealias Parameters = [(String?, type, expression?)]

functionNaming(
    "function",
    [[(nil, Int, nil), (nil, Float, nil)]],
    [("param3", String, nil)],
    [[("param4", Int, nil)]],
    (Arrow Int)
)
// -> "function_IntFloat_fparam3String_Fparam4Int_Int"

functionNaming("function", [], [[]], [], nil)
// -> "function__Void"

func functionNaming(Identifier,
                    _ curriedParameterClauses: [Parameters],
                    _ givenParameters: Parameters,
                    _ remainedParameterClauses: [Parameters],
                    function-result(-> Arrow type)?) -> String {
    let parametersNaming = { (ps: Parameters) -> String in
        ps.reduce("", combine: { $0 + ($1.0 ?? "") + nameof($1.1) })
    }
    let curriedName = curriedParameterClauses.reduce(
        Identifier,
        combine: { $0 + "_" + parametersNaming($1) }
    )
    let givenName = "_f" + parametersNaming(givenParameters)
    let name = remainedParameterClauses.reduce(
        curriedName + givenName,
        combine: { $0 + "_F" + parametersNaming($1) }
    )
    if curriedParameterClauses.count > 0 {
        return "C\(name)_\(nameof(type))"
    } else {
        return "\(name)_\(nameof(type))"
    }
}
```

### Function typing theories

```swift
func functionReturnTyping(_ remainedParameterClauses: [Parameters],
                          function-result(-> Arrow type)?) -> String {
    return remainedParameterClauses.count > 0 ? "%treeswift.function" : typeof(type)
}
```

```swift
func functionParameterTyping(_ curriedParameterClauses: [Parameters],
                             _ givenParameters: Parameters) -> String {
    let code = ", ".join(givenParameters.map({ typeof($0.1) }))
    if curriedParameterClauses.count > 0 {
        code = code + ", i8*"
    }
    return code
}
```

### Function declaration

function-declaration (-> Func Identifier parameter-clauses(-> parameter-clause parameter-clauses') function-result code-block) =
```llvm
%treeswift.function = type { i8*, i8* }

declare i32 @printf(i8*, ...)
declare i8* @malloc(i32)
declare void @free(i8*)

; let parameterClauses = parameter-clauses...

; for var i = 0; i < parameterClauses.count; ++i {
    ; let curried = parameterClauses[0..<i]
    ; let given = parameterClauses[i]
    ; let remained = parameterClauses[i + 1..<parameterClauses.count]
    ; let name = functionNaming(Identifier, curried, given, remained, function-result)
    ; let returnType = functionReturnTyping(remained, function-result)
    ; let parameterType = functionParameterTyping(curried, given)

    ; if curried.count > 0 {

define internal \(returnType) \(name)(\(parameterType)) {
entry:
  ; code-block($0)... [*1]
}

    ; } else {

define linkonce_odr hidden \(returnType) \(name)(\(parameterType)) {
entry:
  ; code-block($0)... [*1]
}

    ; }
; }
```

[*1] Parameters should be associated with its internal name before the expansion.

parameter-clauses (-> parameter-clause) =
```llvm
  ; return [parameter-clause...]
```

parameter-clauses (-> parameter-clause parameter-clauses) =
```llvm
  ; return (parameter-clauses...).insert(parameter-clause..., atIndex: 0)
```

parameter-clause (-> LeftParenthesis RightParenthesis) =
```llvm
  ; return []
```

parameter-clause (-> LeftParenthesis parameter-list RightParenthesis) =
```llvm
  ; return parameter-list...
```

parameter-list (-> parameter) =
```llvm
  ; return [parameter...]
```

parameter-list (-> parameter parameter-list-tail) =
```llvm
  ; return (parameter-list-tail...).insert(parameter..., atIndex: 0)
```

parameter-list-tail (-> Comma parameter-list) =
```llvm
  ; return parameter-list...
```

parameter (-> (Let | Var)? Hash? external-parameter-name? local-parameter-name type-annotation default-argument-clause(-> AssignmentOperator expression)?) =
```llvm
  ; TODO use Hash? and local-parameter-name for compile following code-block
  ; return (external-parameter-name?..., type-annotation, expression?)
```

parameter (-> Inout (Let | Var)? Hash? external-parameter-name? local-parameter-name type-annotation default-argument-clause(-> AssignmentOperator expression)?) =
```llvm
  ; TODO
  ; return (external-parameter-name?..., type-annotation, expression?)
```

external-parameter-name (-> Identifier) =
```llvm
  ; return Identifier
```

external-parameter-name (-> Underscore) =
```llvm
  ; TODO
```

local-parameter-name (-> Identifier) =
```llvm
  ; return Identifier
```

local-parameter-name (-> Underscore) =
```llvm
  ; TODO
```
