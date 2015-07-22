### Patterns

```
declarational-pattern -> identifier-pattern
                       | wildcard-pattern
                       | declarational-tuple-pattern

conditional-pattern -> primary-pattern pattern-postfixes?

primary-pattern -> wildcard-pattern
                 | conditional-tuple-pattern
                 | value-binding-pattern
                 | enum-case-pattern
                 | type-matching-pattern
                 | expression-pattern

wildcard-pattern -> Underscore type-annotation?

identifier-pattern -> Identifier type-annotation?

value-binding-pattern -> Var conditional-pattern
                       | Let conditional-pattern

declarational-tuple-pattern               -> LeftParenthesis declarational-tuple-pattern-elements? RightParenthesis type-annotation?
declarational-tuple-pattern-elements      -> declarational-tuple-pattern-element declarational-tuple-pattern-elements-tail?
declarational-tuple-pattern-elements-tail -> Comma declarational-tuple-pattern-element
declarational-tuple-pattern-element       -> declarational-pattern
                                           | Identifier Colon declarational-pattern

conditional-tuple-pattern               -> LeftParenthesis conditional-tuple-pattern-elements? RightParenthesis type-annotation?
conditional-tuple-pattern-elements      -> conditional-tuple-pattern-element tuple-pattern-elements-tail?
conditional-tuple-pattern-elements-tail -> Comma conditional-tuple-pattern-element
conditional-tuple-pattern-element       -> conditional-pattern
                                         | Identifier Colon conditional-pattern

enum-case-pattern -> type-identifier? Dot Identifier conditional-tuple-pattern?

type-pattern -> Is type

expression-pattern -> expression

pattern-postfixes -> pattern-postfix pattern-postfixes?
pattern-postfix   -> optional-pattern
                   | type-casting-pattern

optional-pattern -> PostfixQuestion

type-casting-pattern -> As type
```
