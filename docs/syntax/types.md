### Types

```
type-annotation -> Colon attributes? type

type -> primary-type type-postfixes?

primary-type -> type-identifier
              | array-type
              | dictionary-type
              | tuple-type
              | protocol-composition-type

type-identifier -> Identifier generic-argument-clause? nested-type?
nested-type     -> Dot type-identifier

array-type -> LeftBracket type RightBracket

dictionary-type -> LeftBracket type Colon type RightBracket

tuple-type                   -> LeftParenthesis tuple-type-body? RightParenthesis
tuple-type-body              -> tuple-type-element-list VariadicSymbol?
tuple-type-element-list      -> tuple-type-element tuple-type-element-list-tail?
tuple-type-element-list-tail -> Comma tuple-type-element-list
tuple-type-element           -> attributes? Inout? type
                              | Inout? Identifier type-annotation

protocol-composition-type     -> Protocol PrefixGraterThan protocol-identifier-list? PostfixLessThan
protocol-identifier-list      -> protocol-identifier protocol-identifier-list-tail?
protocol-identifier-list-tail -> Comma protocol-identifier-list
protocol-identifier           -> type-identifier

type-postfixes -> type-postfix type-postfixes?
type-postfix   -> function-type
                | optional-type
                | implicitly-unwrapped-optional-type
                | metatype-type

function-type -> type (throws | rethrows)? Arrow type

optional-type -> type PostfixQuestion

implicitly-unwrapped-optional-type -> type PostfixExclamation

metatype-type -> type Dot TYPE
               | type Dot PROTOCOL
```
