### Patterns

```
pattern -> wildcard-pattern type-annotation?
         | identifier-pattern type-annotation?
         | value-binding-pattern
         | tuple-pattern type-annotation?

wildcard-pattern -> Underscore

identifier-pattern -> Identifier

value-binding-pattern -> Var pattern | Let pattern

tuple-pattern                   -> LeftParenthesis tuple-pattern-element-list RightParenthesis
                                 | LeftParenthesis RightParenthesis
tuple-pattern-element-list      -> tuple-pattern-element tuple-pattern-element-list-tail?
tuple-pattern-element-list-tail -> Comma tuple-pattern-element-list
tuple-pattern-element           -> pattern
```
