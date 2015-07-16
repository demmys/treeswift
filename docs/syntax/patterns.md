### Patterns

```
pattern -> identifier-pattern
         | wildcard-pattern
         | tuple-pattern
         | expression-pattern
         | value-binding-pattern
         | enum-case-pattern
         | optional-pattern
         | type-casting-pattern

declarational-pattern -> identifier-pattern
                       | wildcard-pattern
                       | declarational-tuple-pattern

conditional-pattern -> wildcard-pattern
                     | tuple-pattern
                     | expression-pattern
                     | value-binding-pattern
                     | enum-case-pattern
                     | optional-pattern
                     | type-casting-pattern

wildcard-pattern -> Underscore type-annotation?

identifier-pattern -> Identifier type-annotation?

value-binding-pattern -> Var pattern
                       | Let pattern

declarational-tuple-pattern               -> LeftParenthesis declarational-tuple-pattern-elements? RightParenthesis
declarational-tuple-pattern-elements      -> declarational-pattern declarational-tuple-pattern-elements-tail?
declarational-tuple-pattern-elements-tail -> Comma declarational-pattern

tuple-pattern               -> LeftParenthesis tuple-pattern-elements? RightParenthesis
tuple-pattern-elements      -> pattern tuple-pattern-elements-tail?
tuple-pattern-elements-tail -> Comma pattern

enum-case-pattern -> type-identifier? Dot enum-case-name tuple-pattern?

optional-pattern         -> pattern PostfixQuestion

type-casting-pattern -> Is type
                      | pattern As type

expression-pattern -> expression
```
