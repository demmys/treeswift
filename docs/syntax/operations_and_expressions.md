### Operation

```
operation -> expression
           | assignment-operation
           | break-operation
           | continue-operation
           | fallthrough-operation
           | return-operation
           | throw-operation

assignment-operation -> declarative-pattern AssignmentOperator expression

break-operation -> Break Identifier?

continue-operation -> Continue Indentifier?

fallthrough-operation -> Fallthrough

return-operation -> Return expression?

throw-operation -> Throw expression
```

### Expression

```
expression-list      -> expression expression-list-tail?
expression-list-tail -> Comma expression-list

expression -> try-operator? prefix-expression binary-expression?

try-operator -> Try | Try PostfixExclamation

binary-expression  -> BinaryOperator prefix-expression binary-expression?
                    | BinaryQuestion expression Colon expression
                    | type-casting-operator binary-expression?

type-casting-operator -> Is type
                       | As type
                       | As PostfixQuestion type
                       | As PostfixExclamation type

prefix-expression -> PrefixOperator? postfix-expression
                   | in-out-expression
in-out-expression -> PrefixAmpersand value-reference

postfix-expression           -> primary-expression postfix-expression-tail?
postfix-expression-tail      -> postfix-expression-tail-body postfix-expression-tail?
postfix-expression-tail-body -> PostfixOperator
                              | function-call-expression
                              | initializer-expression
                              | explicit-member-expression
                              | postfix-self-expression
                              | dynamic-type-expression
                              | subscript-expression
                              | forced-value-expression
                              | optional-chaining-expression

function-call-expression -> tuple-expression /* closure-expression? */
                          /* | closure-expression */

initializer-expression -> Dot Init

explicit-member-expression -> Dot DecimalDigits
                            | Dot Identifier generic-argument-clause?

postfix-self-expression -> Dot Self

dynamic-type-expression -> Dot DynamicType

subscript-expression -> LeftBracket expression-list RightBracket

forced-value-expression -> PostfixExclamation

optional-chaining-expression -> PostfixQuestion

primary-expression -> value-reference generic-argument-clause?
                    | literal-expression
                    | self-expression
                    | superclass-expression
                    | closure-expression
                    | tuple-expression
                    | implicit-member-expression
                    | wildcard-expression

literal-expression -> literal
                    | array-literal
                    | dictionary-literal
                    | FILE | LINE | COLUMN | FUNCTION

array-literal            -> LeftBracket array-literal-items? RightBracket
array-literal-items      -> array-literal-item array-literal-items-tail? Comma?
array-literal-items-tail -> Comma array-literal-items
array-literal-item       -> expression

dictionary-literal            -> LeftBracket dictionary-literal-items RightBracket
                               | LeftBracket Colon RightBracket
dictionary-literal-items      -> dictionary-literal-item dictionary-literal-items-tail? Comma?
dictionary-literal-items-tail -> Comma dictionary-literal-items
dictionary-literal-item       -> expression Colon expression

self-expression -> Self
                 | Self Dot Identifier
                 | Self LeftBracket expression-list RightBracket
                 | Self Dot Init

superclass-expression -> Super Dot Identifier
                       | Super LeftBracket expression RightBracket
                       | Super Dot Init

closure-expression   -> LeftBrace closure-signature? procedures RightBrace
closure-signature    -> capture-clause closure-type-clause? In
                      | closure-type-clause In
closure-type-clause  -> parameter-clause function-result?
                      | identifier-list function-result?
identifier-list      -> value-reference identifier-list-tail?
identifier-list-tail  | Comma identifier-list
capture-clause       -> LeftBracket capture-list RightBracket
capture-list         -> capture-specifier? expression capture-list-tail?
capture-list-tail    -> Comma capture-list
capture-specifier    -> Weak | Unowned
                      | Unowned LeftParenthesis Safe RightParenthesis
                      | Unowned LeftParenthesis Unsafe RightParenthesis

implicit-member-expression -> Dot Identifier

tuple-expression              -> LeftParenthesis expression-element-list? RightParenthesis
expression-element-list       -> expression-element expression-element-list-tail?
expression-element-list-tail  -> Comma expression-element-list
expression-element            -> expression
                               | Identifier Colon expression

wildcard-expression -> Underscore
```
