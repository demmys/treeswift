### Constant declaration, Variable declaration

constant-declaration (-> Let pattern-initializer pattern-initializer-tail?) [*1] =
```llvm
  ; pattern-initializer($0)...
  ; pattern-initializer-tail?($0)...
```

[*1] Assigning to a constant should be detected and rejected at the semantic analyzation.

variable-declaration (-> Var pattern-initializer pattern-initializer-tail?) =
```llvm
  ; pattern-initializer($0)...
  ; pattern-initializer-tail?($0)...
```

pattern-initializer (-> identifier-pattern(-> Identifier) Colon type) =
```llvm
  %\(Identifier) = alloca \(typeof(type($0)))
```

pattern-initializer (-> identifier-pattern(-> Identifier) AssignmentOperator expression) =
```llvm
  %0 = \(expression($0)...)
  %\(Identifier) = alloca \(typeof(expression($0)))
  store \(typeof(expression($0))) %0, \(typeof(expression($0)))* %\(Identifier)
```

pattern-initializer (-> identifier-pattern(-> Identifier) Colon type AssignmentOperator expression) =
```llvm
  %0 = \(expression($0)...)
  %\(Identifier) = alloca \(typeof(type($0)))
  store \(typeof(type($0))) %0, \(typeof(type($0)))* %\(Identifier)
```

pattern-initializer (-> tuple-pattern Colon type) =
```llvm
  ; TODO
```

pattern-initializer (-> tuple-pattern AssignmentOperator expression) =
```llvm
  ; TODO
```

pattern-initializer (-> tuple-pattern Colon type AssignmentOperator expression) =
```llvm
  ; TODO
```
