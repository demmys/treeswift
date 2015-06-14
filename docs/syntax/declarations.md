### Declarations

```
declarations -> declaration declarations?
declaration  -> import-declaration
              | constant-declaration
              | variable-declaration
              | typealias-declaration
              | function-declaration
              | enum-declaration
              | struct-declaration
              | class-declaration
              | protocol-declaration
              | initializer-declaration
              | deinitializer-declaration
              | extension-declaration
              | subscript-declaration
              | operator-declaration

code-block -> LeftBrace statements? RightBrace

type-inheritance-clause      -> Colon Class type-inheritance-clause-tail?
                              | Colon type-inheritance-list
type-inheritance-clause-tail -> Comma type-inheritance-list
type-inheritance-list        -> type-identifier type-inheritance-list-tail?
type-inheritance-list-tail   -> Comma type-inheritance-list
```

#### Import declaration

```
import-declaration -> attributes? Import import-kind? import-path

import-kind            -> Typealias | Struct | Class | Enum | Protocol | Var | Func
import-path            -> import-path-identifier import-path-tail?
import-path-tail       -> Dot import-path
import-path-identifier -> Identifier | PrefixOperator | BinaryOperator | PostfixOperator
```

#### Constant declaration, Variable declaration

```
constant-declaration -> attributes? declaration-modifiers? Let pattern-initializer-list

variable-declaration       -> variable-declaration-head pattern-initializer-list
                            | variable-declaration-head variable-name type-annotation variable-declaration-block
                            | variable-declaration-head variable-name initializer willSet-didSet-block
variable-declaration-block -> code-block
                            | getter-setter-block
                            | getter-setter-keyword-block
                            | initializer? willSet-didSet-block
variable-declaration-head  -> attributes? declaration-modifiers? Var
variable-name              -> Identifier

getter-setter-block -> LeftBrace getter-clause setter-clause? RightBrace
                     | LeftBrace setter-clause getter-clause RightBrace
getter-clause       -> attributes? Get code-block
setter-clause       -> attributes? Set setter-name? code-block
setter-name         -> LeftParenthesis Identifier RightParenthesis

getter-setter-keyword-block -> LeftBrace getter-keyword-clause setter-keyword-clause? RightBrace
                             | LeftBrace setter-keyword-clause getter-keyword-clause RightBrace
getter-keyword-clause       -> attributes? Get
setter-keyword-clause       -> attributes? Set

willSet-didSet-block -> LeftBrace willSet-clause didSet-clause? RightBrace
                      | LeftBrace didSet-clause willSet-clause? RightBrace
willSet-clause       -> attributes? WillSet setter-name? code-block
didSet-clause        -> attributes? DidSet setter-name? code-block

pattern-initializer-list -> pattern-initializer pattern-initializer-tail?
pattern-initializer-tail -> Comma pattern-initializer-list
pattern-initializer      -> pattern initializer?
initializer              -> BinaryEqual expression
```

#### Typealias declaration

```
typealias-declaration -> typealias-head typealias-assignment
typealias-head        -> attributes? access-level-modifier? Typealias typealias-name
typealias-name        -> Identifier
typealias-assignment  -> BinaryEqual type
```

#### Function declaration

```
function-declaration -> function-head function-name generic-parameter-clause? function-signature function-body

function-head      -> attributes? declaration-modifiers? Func
function-name      -> Identifier | PrefixOperator | PostfixOperator | BinaryOperator
function-signature -> parameter-clauses (Throws | Rethrows)? function-result?
function-result    -> Arrow attributes? type
function-body      -> code-block

parameter-clauses       -> parameter-clause parameter-clauses?
parameter-clause        -> LeftParenthesis RightParenthesis
                         | LeftParenthesis parameter-list RightParenthesis
parameter-list          -> parameter parameter-list-tail?
parameter-list-tail     -> Comma parameter-list
parameter               -> Inout? (Let | Var)? Hash? external-parameter-name? local-parameter-name type-annotation default-argument-clause?
                         | attributes? type
external-parameter-name -> Identifier | Underscore
local-parameter-name    -> Identifier | Underscore
default-argument-clause -> BinaryEqual expression
```

#### Enum declaration

```
enum-declaration      -> attributes? access-level-modifier? enum-declaration-body
enum-declaration-body -> union-style-enum
                       | raw-value-style-enum

union-style-enum         -> Enum Identifier generic-parameter-clause? type-inheritance-clause? LeftBrace union-style-enum-members? RightBrace
union-style-enum-members -> union-style-enum-member union-style-enum-members?
union-style-enum-member  -> declaration
                          | union-style-enum-case-clause

union-style-enum-case-clause -> attributes? Case union-style-enum-case-list
union-style-enum-case-list   -> union-style-enum-case union-style-enum-case-tail?
union-style-enum-case-tail   -> Comma union-style-enum-case-list
union-style-enum-case        -> enum-case-name tuple-type?

raw-value-style-enum         -> Enum Identifier generic-parameter-clause? type-inheritance-clause LeftBrace raw-value-style-enum RightBrace
raw-value-style-enum-members -> raw-value-style-enum-member raw-value-style-enum-members?
raw-value-style-enum-member  -> declaration
                              | raw-value-style-enum-case-clause

raw-value-style-enum-case-clause -> attributes? Case raw-value-style-enum-case-list
raw-value-style-enum-case-list   -> raw-value-style-enum-case raw-value-style-enum-case-tail?
raw-value-style-enum-case-tail   -> Comma raw-value-style-enum-case-list
raw-value-style-enum-case        -> enum-case-name raw-value-assignment?
raw-value-assignment             -> BinaryEqual raw-value-literal
raw-value-literal                -> numeric-literal
                                  | StringLiteral

enum-case-name -> Identifier
```

#### Struct declaration

```
struct-declaration -> attributes? access-level-modifier? Struct Identifier generic-parameter-clause? type-inheritance-clause? struct-body
struct-body        -> LeftBrace declarations RightBrace
```

#### Class declaration

```
class-declaration -> attributes? access-level-modifier? Class Identifier generic-parameter-clause? type-inheritance-clause? class-body
class-body        -> LeftBrace declarations RightBrace
```

#### Protocol declaration

```
protocol-declaration -> attributes? access-level-modifier? Protocol Identifier type-inheritance-clause? protocol-body
protocol-body        -> LeftBrace protocol-member-declarations? RightBrace

protocol-member-declarations -> protocol-member-declaration protocol-declarations?
protocol-member-declaration  -> protocol-property-declaration
                              | protocol-method-declaration
                              | protocol-initializer-declaration
                              | protocol-subscript-declaration
                              | protocol-associated-type-declaration

protocol-property-declaration -> variable-declaration-head variable-name type-annotation getter-setter-keyword-block

protocol-method-declaration -> function-head function-name generic-parameter-clause? function-signature

protocol-initializer-declaration -> initializer-head generic-parameter-clause? parameter-clause

protocol-subscript-declaration -> subscript-head subscript-result getter-setter-keyword-block

protocol-associated-type-declaration ->  typealias-head type-inheritance-clause? typealias-assignment
```

#### Initializer declaration

```
initializer-declaration -> initializer-head generic-parameter-clause? parameter-clause code-block
initializer-head        -> attributes? declaration-modifiers? Init (PostfixQuestion | PostfixExclamation)?
```

#### Deinitializer declaration

```
deinitializer-declaration -> attributes? Deinit code-block
```

#### Extension declaration

```
extension-declaration -> access-level-modifier? Extension type-identifier type-inheritance-clause? extension-body
extension-body        -> Leftbrace declarations RightBrace
```

#### Subscript declaration

```
subscript-declaration -> subscript-head subscript-result code-block
                       | subscript-head subscript-result getter-setter-block
                       | subscript-head subscript-result getter-setter-keyword-block
subscript-head        -> attributes? declaration-modifiers? Subscript parameter-clause
subscript-result      -> Arrow attributes? type
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

#### Declaration modifier

```
declaration-modifiers -> declaration-modifier declaration-modifiers?
declaration-modifier  -> Class | Convenience | Dynamic | Final | Infix | Lazy | Mutating | Nonmutating
                       | Optional | Override | Postfix | Prefix | Required | Static
                       | Unowned | Unowned LeftParenthesis Safe RightParenthesis
                       | Unowned LeftParenthesis Unsafe RightParenthesis | Weak
                       | access-level-modifier

access-level-modifiers -> access-level-modifier access-level-modifiers?
access-level-modifier  -> Internal | Internal LeftParenthesis Set RightParenthesis
                        | Private | Private LeftParenthesis Set RightParenthesis
                        | Public | Public LeftParenthesis Set RightParenthesis
```
