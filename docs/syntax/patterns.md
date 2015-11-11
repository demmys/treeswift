### Patterns

```
declarative-pattern -> identifier-pattern
                       | wildcard-pattern
                       | declarative-tuple-pattern

conditional-pattern -> primary-pattern pattern-postfixes?

primary-pattern -> wildcard-pattern
                 | conditional-tuple-pattern
                 | value-binding-pattern
                 | enum-case-pattern
                 | type-pattern
                 | expression-pattern

wildcard-pattern -> Underscore

identifier-pattern -> Identifier

value-binding-pattern -> Var conditional-pattern
                       | Let conditional-pattern

declarative-tuple-pattern               -> LeftParenthesis declarative-tuple-pattern-elements? RightParenthesis type-annotation?
declarative-tuple-pattern-elements      -> declarative-tuple-pattern-element declarative-tuple-pattern-elements-tail?
declarative-tuple-pattern-elements-tail -> Comma declarative-tuple-pattern-element
declarative-tuple-pattern-element       -> declarative-pattern
                                           | Identifier Colon declarative-pattern

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
