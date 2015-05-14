### Types

```
type -> type-identifier
      | tuple-type
      | function-type
      | array-type

type-annotation -> Colon type

type-identifier -> Identifier

tuple-type                   -> LeftParenthesis tuple-type-body RightParenthesis
                              | LeftParenthesis Rightparenthesis
tuple-type-body              -> tuple-type-element-list
tuple-type-element-list      -> tuple-type-element tuple-type-element-list-tail?
tuple-type-element-list-tail -> Comma tuple-type-element-list
tuple-type-element           -> Inout? type
                              | Inout? Identifier type-annotation

function-type -> type Arrow type

array-type -> LeftBracket type RightBracket
```
