### Loop statement

loop-statement (-> *) =
```llvm
  ; *(Context(parent: $0))...
```

for-statement (-> For LeftParenthesis? for-init? Semicolon expression Semicolon expression? RightParenthesis? code-block) [*1]  =
```llvm
  ; $0.breakLabel = %4
  ; $0.continueLabel = %3
  ; for-init?($0)...
  br label %0

; <label>:0
  %1 = \(expression($0)...)
  br i1 %1, label %2, label %4

; <label>:2
  ; code-block($0)...
  br label %3

; <label>:3
  ; expression?($0)...
  br label %0

; <label>:4
```

for-statement (-> For LeftParenthesis? for-init? Semicolon Semicolon expression? RightParenthesis? code-block) [*1] =
```llvm
  ; $0.breakLabel = %2
  ; $0.continueLabel = %1
  ; for-init?($0)...
  br label %0

; <label>:0
  ; code-block($0)...
  br label %1

; <label>:1
  ; expression?($0)...
  br label %0

; <label>:2
```

[*1] Only the appearance of `expression` symbol (expanded from `for-confirmation`) differs.

for-init (-> *) =
```llvm
  ; *($0)...
```

for-in-statement (-> For pattern In expression code-block) =
```llvm
  ; TODO
```

while-statement (-> While expression code-block) =
```llvm
  ; $0.breakLabel = %3
  ; $0.continueLabel = %0
  br label %0

; <label>:0
  %1 = \(expression($0)...)
  br i1 %1, label %2, label %3

; <label>:2
  ; code-block($0)...
  br label %0

; <label>:3
```

while-statement (-> While declaration code-block) =
```llvm
  ; TODO
```

do-while-statement (-> Do code-block While expression) =
```llvm
  ; $0.breakLabel = %2
  ; $0.continueLabel = %0
  br label %0

; <label>:0
  ; code-block($0)...
  %1 = \(expression($0)...)
  br i1 %1, label %0, label %2

; <label>:2
```
