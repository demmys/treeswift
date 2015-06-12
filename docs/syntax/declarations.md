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
constant-declaration -> Let pattern-initializer-list

variable-declaration      -> variable-declaration-head pattern-initializer-list
variable-declaration-head -> Var

pattern-initializer-list -> pattern-initializer pattern-initializer-tail?
pattern-initializer-tail -> Comma pattern-initializer-list
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
                         | LeftParenthesis parameter-list RightParenthesis
parameter-list          -> parameter parameter-list-tail?
parameter-list-tail     -> Comma parameter-list
parameter               -> Inout? (Let | Var)? Hash? external-parameter-name? local-parameter-name type-annotation default-argument-clause?
external-parameter-name -> Identifier | Underscore
local-parameter-name    -> Identifier | Underscore
default-argument-clause -> AssignmentOperator expression
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
