# Non terminal symbol

### Top level declaration

```
top-level-declaration -> statements?
```

### Statements

```
statements -> statement statements?

statement      -> statement-head (LineFeed | Semicolon | EndOfFile)
statement-head -> expression
                | declaration
                | loop-statement
                | branch-statement
                | labeled-statement
                | control-transfer-statement
```

#### Loop statement

```
loop-statement -> for-statement
                | for-in-statement
                | while-statement
                | do-while-statement

for-statement    -> For for-condition code-block
                  | For LeftParenthesis for-condition RightParenthesis code-block
for-condition    -> for-init? Semicolon for-confirmation? Semicolon for-execute-post?
for-init         -> variable-declaration
                  | expression-list
for-confirmation -> expression \ze ^Semicolon
for-finalize -> expression \ze ^LeftBrace

for-in-statement -> For pattern In expression code-block

while-statement -> While while-condition code-block
while-condition -> expression
                 | declaration

do-while-statement -> Do code-block while while-condition
```

#### Branch statement

```
branch-statement -> if-statement

if-statement -> If if-condition code-block else-clause?
if-condition -> expression
else-clause  -> Else code-block
              | Else if-statement
```

#### Labeled statement

```
labeled-statement -> statement-label loop-statement
statement-label   -> label-name Colon
label-name        -> Identifier
```

#### Control transfer statement

```
control-transfer-statement -> break-statement
                            | continue-statement
                            | return-statement

break-statement -> Break label-name?

continue-statement -> Continue label-name?

return-statement -> Return
                  | Return expression
```

### Declarations

```
declaration -> constant-declaration
             | variable-declaration
             | typealias-declaration
             | function-declaration
             | operator-declaration

code-block -> LeftBrace statements? RightBrace
```

#### Constant declaration, Variable declaration

```
constant-declaration -> Let pattern-initializer pattern-initializer-tail?

variable-declaration      -> variable-declaration-head pattern-initializer pattern-initializer-tail
variable-declaration-head -> Var

pattern-initializer-tail -> Comma pattern-initializer pattern-initializer-tail?
pattern-initializer      -> pattern initializer?
initializer              -> AssignmentOperator expression
```

#### Typealias declaration

```
typealias-declaration -> typealias-head typealias-assignment
typealias-head        -> Typealias typealias-name
typealias-name        -> Identifier
typealias-assignment  -> AssignmentOperator type
```

#### Function declaration

```
function-declaration -> function-head function-name function-signature function-body

function-head      -> Func
function-name      -> Identifier | PrefixOperator | PostfixOperator | BinaryOperator
function-signature -> parameter-clauses function-result?
function-result    -> Arrow type
function-body      -> code-block

parameter-clauses       -> parameter-clause parameter-clauses?
parameter-clause        -> LeftParenthesis RightParenthesis
                         | Leftparenthesis parameter-list RightParenthesis
parameter-list          -> parameter parameter-list-tail?
parameter-list-tail     -> Comma parameter-list
parameter               -> Inout? (Let | Var)? Hash? external-parameter-name? local-parameter-name type-annotation default-argument-clause?
external-parameter-name -> Identifier | Underscore
local-parameter-name    -> Identifier | Underscore
default-argument-clause -> Assignmentoperator expression
```

#### Operator declaration

```
operator-declaration -> prefix-operator-declaration
                      | postfix-operator-declaration
                      | infix-operator-declaration

prefix-operator-declaration -> Prefix Operator BinaryOperator LeftBrace RightBrace

postfix-operator-declaration -> Postfix Operator BinaryOperator LeftBrace RightBrace

infix-operator-declaration -> Infix Operator BinaryOperator LeftBrace infix-operator-attributes? RightBrace
infix-operator-attributes  -> precedence-clause? associativity-clause?
precedence-clause          -> Precedence precedence-level
precedence-level           -> DecimalDigits(0...255)
associativity-clause       -> Associativity associativity
associativity              -> Left | Right | None
```

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

### Expressions

```
expression-list      -> expression expression-list-tail
expression-list-tail -> Comma expression-list

expression -> prefix-expression binary-expressions?
            | in-out-expression

in-out-expression -> Ampersand Identifier

binary-expressions -> binary-expression binary-expressions?
binary-expression  -> BinaryOperator prefix-expression
                    | AssignmentOperator prefix-expression
                    | conditional-operator prefix-expression
                    | type-casting-operator

conditional-operator -> BinaryQuestion expression Colon

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
                            | trailing-closure
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
capture-list         -> capture-specifier? expression
capture-specifier    -> Weak | Unowned

parenthesized-expression      -> LeftParenthesis expression-element-list? RightParenthesis
expression-element-list       -> expression-element expression-element-list-tail?
expression-element-list-tail  -> Comma expression-element-list
expression-element            -> expression
                               | Identifier Colon expression

wildcard-expression -> Underscore

```

### Literals

```
literal -> IntegerLiteral
         | True
         | False
         | Nil
```


# Terminal symbol

### IgnoredSymbol

```
IgnoredSymbol -> space
               | line-comment
               | block-comment

space -> '[ \t\0\r\u{000b}\u{000c}]'

block-comment -> '/\*.*' block-comment? '.*\*/'

line-comment -> '//.*' \ze [LineFeed|EndOfFile]
```

### EndOfFile

```
EndOfFile -> 'EOF'
```

### LineFeed

```
LineFeed -> '\n'
```

### Symbols

```
Semicolon -> ';'

Colon -> ':'

Comma -> ','

Arrow -> '->'

Hash -> '#'

Underscore -> '_'

Ampersand -> '&'

PrefixQuestion -> '?'
BinaryQuestion -> '?'
PostfixQuestion -> '?'

Dollar -> '$'
```

### Brackets

```
LeftParenthesis  -> '('
RightParenthesis -> ')'

LeftBrace  -> '{'
RightBrace -> '}'

LeftBracket ->  '['
RightBracket -> ']'
```

### Words

```
As -> 'as'

Associativity -> 'associativity'

Break -> 'break'

Continue -> 'continue'

Do -> 'do'

Else -> 'else'

False -> 'false'

For -> 'for'

Func -> 'func'

If -> 'if'

Infix -> 'infix'

In -> 'in'

Inout -> 'inout'

Is -> 'is'

Let -> 'let'

Left -> 'left'

None -> 'none'

Nil -> 'nil'

Operator -> 'operator'

Prefix -> 'prefix'

Postfix -> 'postfix'

Precedence -> 'precedence'

Return -> 'return'

Right -> 'right'

True -> 'true'

Typealias -> 'typealias'

Unowned -> 'unowned'

Var -> 'var'

Weak -> 'weak'

While -> 'while'
```

### Identifier

```
Identifier -> identifier-head identifier-character*
            | '`' identifier-head identifier-character* '`'
            | implicit-parameter-name

implicit-parameter-name -> Dollar '[0-9]+'

identifier-head      -> '[a-zA-Z_
                          \u{00A8}
                          \u{00AA}
                          \u{00AD}
                          \u{00AF}
                          \u{00B2}-\u{00B5}
                          \u{00B7}-\u{00BA}
                          \u{00BC}-\u{00BE}
                          \u{00C0}-\u{00D6}
                          \u{00D8}-\u{00F6}
                          \u{00F8}-\u{00FF}
                          \u{0100}-\u{02FF}
                          \u{0370}-\u{167F}
                          \u{1681}-\u{180D}
                          \u{180F}-\u{1DBF}
                          \u{1E00}-\u{1FFF}
                          \u{200B}-\u{200D}
                          \u{202A}-\u{202E}
                          \u{203F}-\u{2040}
                          \u{2054}
                          \u{2060}-\u{206F}
                          \u{2070}-\u{20CF}
                          \u{2100}-\u{218F}
                          \u{2460}-\u{24FF}
                          \u{2776}-\u{2793}
                          \u{2C00}-\u{2DFF}
                          \u{2E80}-\u{2FFF}
                          \u{3004}-\u{3007}
                          \u{3021}-\u{302F}
                          \u{3031}-\u{303F}
                          \u{3040}-\u{D7FF}
                          \u{F900}-\u{FD3D}
                          \u{FD40}-\u{FDCF}
                          \u{FDF0}-\u{FE1F}
                          \u{FE30}-\u{FE44}
                          \u{FE47}-\u{FFFD}
                          \u{10000}-\u{1FFFD}
                          \u{20000}-\u{2FFFD}
                          \u{30000}-\u{3FFFD}
                          \u{40000}-\u{4FFFD}
                          \u{50000}-\u{5FFFD}
                          \u{60000}-\u{6FFFD}
                          \u{70000}-\u{7FFFD}
                          \u{80000}-\u{8FFFD}
                          \u{90000}-\u{9FFFD}
                          \u{A0000}-\u{AFFFD}
                          \u{B0000}-\u{BFFFD}
                          \u{C0000}-\u{CFFFD}
                          \u{D0000}-\u{DFFFD}
                          \u{E0000}-\u{EFFFD}
                         ]'
identifier-character -> identifier-head
                      | '[0-9
                          \u{0300}-\u{036F}
                          \u{1DC0}-\u{1DFF}
                          \u{20D0}-\u{20FF}
                          \u{FE20}-\u{FE2F}
                         ]'
```

### IntegerLiteral

```
DecimalDigits -> '[0-9]+'

IntegerLiteral  -> integer-literal

integer-literal -> binary-literal
                 | octal-literal
                 | decimal-literal
                 | hexadecimal-literal

binary-literal      -> '0b[01][01_]*'
octal-literal       -> '0o[0-7][0-7_]*'
decimal-literal     -> '[0-9][0-9_]*'
hexadecimal-literal -> '0x[0-9a-f][0-9a-f_]*'
```

### Operators

```
AssignmentOperator -> '='

BinaryOperator -> front-separator \zs operator \ze back-separator
                | [^front-separator] \zs operator \ze [^back-separator]
                | dot-front-separator \zs dot-operator \ze dot-back-separator
                | [^dot-front-separator] \zs dot-operator \ze [^dot-back-separator]

PrefixOperator -> front-separator \zs operator \ze [^back-separator]
                | dot-front-separator \zs dot-operator \ze [^dot-back-separator]

PostfixOperator -> [^front-separator] operator \ze back-separator
                 | [^dot-front-separator] dot-operator \ze dot-back-separator

front-separator     = default-separator | LeftParenthesis
dot-front-separator = separator | LeftParenthesis
back-separator      = default-separator | RightParenthesis
dot-back-separator  = separator | RightParenthesis
default-separator   = separator | Dot
separator           = Space | EndOfFile | LineFeed | Semicolon | Colon | Comma

operator     -> operator-head operator-character*
dot-operator -> '..' ['.'|operator-character]*

operator-head      -> '[/=-+!*%<>&|^?~
                       \u{00a1}-\u{00a7}
                       \u{00a9}
                       \u{00ab}
                       \u{00ac}
                       \u{00ae}
                       \u{00b0}
                       \u{00b1}
                       \u{00b6}
                       \u{00bb}
                       \u{00bf}
                       \u{00d7}
                       \u{00f7}
                       \u{2016}
                       \u{2017}
                       \u{2020}-\u{2027}
                       \u{2030}-\u{203e}
                       \u{2041}-\u{2053}
                       \u{2055}-\u{205e}
                       \u{2190}-\u{23ff}
                       \u{2500}-\u{2775}
                       \u{2794}-\u{2bff}
                       \u{2e00}-\u{2e7f}
                       \u{3001}-\u{3003}
                       \u{3008}-\u{3030}
                      ]'
operator-character -> operator-head
                    | '[
                       \u{0300}-\u{036f}
                       \u{1dc0}-\u{1dff}
                       \u{20d0}-\u{20ff}
                       \u{fe00}-\u{fe0f}
                       \u{fe20}-\u{fe2f}
                       \u{e0100}-\u{e01ef}
                      ]'
```
