### Expressions

expression-list -> expression Comma expression-list
```llvm
; TODO
```

expression -> PrefixAmpersand Identifier
```llvm
; TODO
```

expression -> prefix-expression binary-expressions?
```llvm
  %0 = \(prefix-expression($0)...)
  ; $0.push(%0)
  binary-expressions?($0)...
```

binary-expressions -> binary-expression binary-expressions?
```llvm
  %0 = \(binary-expression($0)...)
  ; $0.push(%0)
  binary-expressions?($0)...
```

binary-expression -> BinaryOperator prefix-expression
```llvm
  %0 = \(prefix-expression($0)...)
  ; if let f = $0.findBinaryOperatorFunction {
    ; if let l = $0.pop() {
  %1 = call \(f.1) \(f.0)(\(typeof(l)) l, \(typeof(%0)) %0)
    ; } else {
      ; // raise error
    ; }
  ; } else {
    ; // raise error
  ; return %1
```

binary-expression -> AssignmentOperator prefix-expression
binary-expression -> BinaryQuestion expression Colon prefix-expression
binary-expression -> type-casting-operator

type-casting-operator -> Is type
                       | As type
                       | As BinaryQuestion type

prefix-expression -> PrefixOperator? postfix-expression

postfix-expression         -> primary-expression postfix-expression-tail?
postfix-expression-tail    -> PostfixOperator postfix-expression-tail?
                            | function-call-expression postfix-expression-tail?
                            | explicit-member-expression postfix-expression-tail?
                            | subscript-expression postfix-expression-tail?
function-call-expression   -> parenthesized-expression trailing-closure?
                            /* | trailing-closure */
explicit-member-expression -> Dot DecimalDigits
                            | Dot Identifier
subscript-expression       -> LeftBracket expression-list RightBracket

primary-expression -> Identifier
                    | literal-expression
                    | closure-expression
                    | parenthesized-expression
                    | wildcard-expression

literal-expression -> literal
                    | array-literal

array-literal            -> LeftBracket array-literal-items? RightBracket
array-literal-items      -> array-literal-item array-literal-items-tail? Comma?
array-literal-items-tail -> Comma array-literal-items
array-literal-item       -> expression

trailing-closure     -> closure-expression
closure-expression   -> LeftBrace closure-signature? statements RightBrace
closure-signature    -> capture-clause closure-type-clause? In
                      | closure-type-clause In
closure-type-clause  -> parameter-clause function-result?
                      | identifier-list function-result?
identifier-list      -> Identifier identifier-list-tail?
identifier-list-tail  | Comma identifier-list
capture-clause       -> LeftBracket capture-list RightBracket
capture-list         -> capture-specifier? expression capture-list-tail?
capture-list-tail    -> Comma capture-list
capture-specifier    -> Weak | Unowned

parenthesized-expression      -> LeftParenthesis expression-element-list? RightParenthesis
expression-element-list       -> expression-element expression-element-list-tail?
expression-element-list-tail  -> Comma expression-element-list
expression-element            -> expression
                               | Identifier Colon expression

wildcard-expression -> Underscore
