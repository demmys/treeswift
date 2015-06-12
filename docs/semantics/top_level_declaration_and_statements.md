### Top level declaration

top-level-declaration (-> statements) =
```llvm
define void @top_level_code() {
entry:
  ; statements(Context())...
  ret void
}

define i32 @main() {
entry:
  call void @top_level_code()
  ret i32 0
}
```

### Statements

statements (-> statement-head (LineFeed | Semicolon | EndOfFile) statements?) =
```llvm
  ; statement-head($0)...
  ; statements?($0)...
```

statement-head (-> *) =
```llvm
  ; *($0)...
```
