### Function naming theories

* All LLVM functions (contains the currying functions) should have an another name.
* The LLVM function name only uses external parameter name.
* Swift functions can be curried with the void parameter.
* The Swift function with the same name can be declared only when these parameter types or parameter clause patterns are different. (Note that two Swift functions which contain the same parameter clause pattern can be declared, but it cannot be called with that pattern. Which causes "Ambiguous function name" error at the compile time.)
* So, we should declare LLVM functions with the full parametered name (even though it is for curring), and parameter clauses are separated with the "f" or "F" character. The character "F" represents that following clause is not considered in the declared LLVM function yet (function name represents that "When "f"ed clauses are given, it will return function with "F"ed clauses").

```swift
func nameof(function-name(-> Identifier)) {
    return "F" + Identifier
}

func nameof(function-name(-> PrefixOperator)) {
    return "O" + encode(PrefixOperator)
}

func nameof(function-name(-> PostfixOperator)) {
    return "O" + encode(PostfixOperator)
}

func nameof(function-name(-> BinaryOperator)) {
    return "O" + encode(BinaryOperator)
}
```

```swift
typealias Parameters = [(String?, type, expression?)]

functionNaming(
    "function",
    [[(nil, Int, nil), (nil, Float, nil)]],
    [("param3", String, nil)],
    [[("param4", Int, nil)]],
    (Arrow Int)
)
// -> "Ffunction_IntFloat_fparam3String_Fparam4Int_Int"

functionNaming("function", [], [[]], [], nil)
// -> "Ffunction__Void"

func functionNaming(function-name,
                    _ curriedParameterClauses: [Parameters],
                    _ givenParameters: Parameters,
                    _ remainedParameterClauses: [Parameters],
                    function-result(-> Arrow type)?) -> String {
    let parametersNaming = { (ps: Parameters) -> String in
        ps.reduce("", combine: { $0 + ($1.0 ?? "") + nameof($1.1) })
    }
    let curriedName = curriedParameterClauses.reduce(
        nameof(function-name),
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
    if remainedParameterClauses.count > 0 {
        return "%treeswift.function"
    }
    if let t = type {
        return typeof(t)
    }
    return "void"
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

### Curried context theories

```swift
func sizeOfContext(_ parameterClauses: [Parameters]) -> Int {
    return parameterClauses.reduce(0, combine: {
        $1.reduce($0, combine: { $0 + sizeof($1.1) })
    })
}
```

```swift
func structOfContext(_ parameterClauses: [Parameters]) -> String {
    return "{ " + ", ".join(parameterClauses.flatMap({ $0.map({ typeof($0) }))) + " }"
}
```

### Function declaration

function-declaration (-> Func function-name parameter-clauses function-result? code-block) =
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
    ; let name = functionNaming(function-name, curried, given, remained, function-result)
    ; let returnType = functionReturnTyping(remained, function-result)
    ; let parameterType = functionParameterTyping(curried, given)

    ; if curried.count == 0 { [*1]
        ; for var i = 0; i < given.count; ++i {
            ; if let defaultExpression = given[i].2 {
define hidden \(typeof(given[i].1)) @\(name)_A\(i)() {
entry:
  %0 = \(defaultExpression(Context(parent: $0.getGlobal()))...) [*2]
}
            ; }
        ; }
    ; }
    ; if remained.count > 0 { [*3]
        ; let size = sizeOfContext(parameterClauses)
        ; let struct = structOfContext(parameterClauses)
        ; var n = given.count + 1
define hidden %treeswift.function @\(name)(\(parameterType)) {
entry:
        ; if curried.count == 0 {
  %\(n) = call i8* @malloc(i32 \(size))
                ; ++n
        ; }
  %\(n) = bitcast i8* %\(n) to \(struct)*
        ; var i = 0
        ; var j = curried.count == 0 ? 0 : curried.flatMap({ $0 }).count
        ; for ; i < given.count; ++i, ++j {
  %\(n + i) = getelementptr inbounds \(struct)* %\(n), i32 0, i32 \(j)
  store \(typeof(given[i].1)) %\(i), \(typeof(given[i].1))* %\(n + i)
        ; }
        ; let nextCurried = [].join([curried, [given]])
        ; let nextGiven = remained[0]
        ; let nextRemained = remained[1..<remained.count]
        ; let nextName = functionNaming(function-name, nextCurried, nextGiven,
                                      ; nextRemained, function-result)
        ; let nextReturnType = functionReturnTyping(nextRemained, function-result)
        ; let nextParameterType = functionParameterTyping(nextCurried, nextGiven)
  %\(n + i) = bitcast \(nextReturnType) (\(nextParameterType))* @\(nextName) to i8*
  %\(n + i + 1) = insertvalue %treeswift.function { i8* undef, i8* undef }, i8* %\(n + i), 0
  %\(n + i + 2) = insertvalue %treeswift.function %\(n + i + 1), i8* %\(n - 1), 1
  ret %treeswift.function %\(n + i + 2)
}
    ; } else {
        ; if curried.count == 0 { [*4]
define hidden \(returnType) @\(name)(\(parameterType)) {
entry:
  ; code-block(Context(parent: $0.getGlobal()))... [*3] [*5]
}
        ; } else { [*6]
        ; let struct = structOfContext(parameterClauses)
        ; var n = given.count + 1
define internal \(returnType) @\(name)(\(parameterType)) {
entry:
  %\(n) = bitcast i8* %\(n - 1) to \(struct)*
        ; let contexts = curried.flatMap({ $0 })
        ; var i = 0
        ; for ; i < contexts.count; ++i {
  %\(n + 2 * i - 1) = getelementptr inbounds \(struct)* %\(n), i32 0, i32 \(i)
  %\(n + 2 * i) = load \(typeof(contexts[i].1)) %\(n + 2 * i - 1)
        ; }
  call void @free(i8* %\(n - 1))
  ; code-block(Context(parent: $0.getGlobal()))... [*3] [*5]
}
        ; }
    ; }
; }
```

[*1] Only not curried functions can have a default value.

[*2] Nested function is not considered yet.

[*3] Represents swift curried function

[*4] Normal function

[*5] Parameters should be associated with its internal name before the expansion.

[*6] Represents end point of Swift curried function

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
