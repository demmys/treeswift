### Patterns

```
pattern -> wildcard-pattern type-annotation?
         | identifier-pattern type-annotation?
         | value-binding-pattern
         | tuple-pattern type-annotation?
         | enum-case-pattern
         | optional-pattern
         | type-casting-pattern
         | expression-pattern

wildcard-pattern -> Underscore

identifier-pattern -> Identifier

value-binding-pattern -> Var pattern | Let pattern

tuple-pattern                   -> LeftParenthesis tuple-pattern-element-list? RightParenthesis
                                 | LeftParenthesis RightParenthesis
tuple-pattern-element-list      -> tuple-pattern-element tuple-pattern-element-list-tail?
tuple-pattern-element-list-tail -> Comma tuple-pattern-element-list
tuple-pattern-element           -> pattern

enum-case-pattern -> type-identifier? Dot enum-case-name tuple-pattern?

optional-pattern -> identifier-pattern PostfixQuestion

type-casting-pattern -> is-pattern
                      | as-pattern
is-pattern           -> Is type
as-pattern           -> pattern as type

expression-pattern -> expression
```
