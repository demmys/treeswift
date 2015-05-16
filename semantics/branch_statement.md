### Branch statement

branch-statement (-> *) =
```llvm
  ; *(Context(parent: c))...
```

if-statement (-> If expression code-block else-clause) =
```llvm
  %0 = \(expression($0)...)
  br i1 %0, label %1, label %2

; <label>:1
  ; code-block($0)...
  br label %3

; <label>:2
  ; else-clause($0)...
  br label %3

; <label>:3
```

if-statement (-> If expression code-block) =
```llvm
  %0 = \(expression($0)...)
  br i1 %0, label %1, label %2

; <label>:1
  ; code-block($0)...
  br label %2

; <label>:2
```

else-clause (-> Else *) =
```llvm
  ; *($0)...
```
