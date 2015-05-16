### Labeled statement

labeled-statement (-> Identifier Colon loop-statement(-> *)) [*1] =
```llvm
  ; *(Context(parent: $0, labelName: Identifier))...
```

[*1] To implement this rule, `loop-statement` should already be expanded in AST.

### Control transfer statement

control-transfer-statement (-> *) =
```llvm
  ; *($0)...
```

break-statement (-> Break) =
```llvm
  br label \($0.breakLabel)
```

break-statement (-> Break Identifier) =
```llvm
  br label \($0.findNamedBreakLabel(Identifier))
```

continue-statement (-> Continue) =
```llvm
  br label \(c.continueLabel)
```

continue-statement (-> Continue Identifier) =
```llvm
  br label \(c.findNamedContinueLabel(Identifier))
```

return-statement (-> Return) =
```llvm
  ret void
```

return-statement (-> Return expression) =
```llvm
  ; %0 = expression($0)...
  ret typeof(%0) %0
```
