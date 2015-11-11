### Declarations

```
declarations -> declaration declarations?
declaration  -> attributes? import-declaration
              | attributes? declaration-modifiers? constant-declaration
              | attributes? declaration-modifiers? variable-declaration
              | attributes? access-level-modifier? typealias-declaration
              | attributes? declaration-modifiers? function-declaration
              | attributes? access-level-modifier? enum-declaration
              | attributes? access-level-modifier? struct-declaration
              | attributes? access-level-modifier? class-declaration
              | attributes? access-level-modifier? protocol-declaration
              | attributes? declaration-modifiers? initializer-declaration
              | attributes? deinitializer-declaration
              | attributes? declaration-modifiers? subscript-declaration
              | access-level-modifier? extension-declaration
              | operator-declaration

type-inheritance-clause      -> Colon Class type-inheritance-clause-tail?
                              | Colon type-inheritance-list
type-inheritance-clause-tail -> Comma type-inheritance-list
type-inheritance-list        -> type-identifier type-inheritance-list-tail?
type-inheritance-list-tail   -> Comma type-inheritance-list
```

### Module declaration

```
module-declarations -> module-declaration module-declarations?
module-declaration -> attributes? import-declaration
                    | attributes? declaration-modifiers? module-constant-declaration
                    | attributes? declaration-modifiers? module-variable-declaration
                    | attributes? access-level-modifier? associated-type-declaration
                    | attributes? declaration-modifiers? module-function-declaration
                    | attributes? access-level-modifier? enum-declaration
                    | attributes? access-level-modifier? module-struct-declaration
                    | attributes? access-level-modifier? module-class-declaration
                    | attributes? access-level-modifier? protocol-declaration
                    | attributes? declaration-modifiers? module-initializer-declaration
                    | attributes? declaration-modifiers? module-subscript-declaration
                    | access-level-modifier? extension-declaration
                    | operator-declaration
```

#### Top level declaration

```
top-level-declaration -> procedures?
```

#### Import declaration

```
import-declaration -> Import import-kind? import-path

import-kind            -> Typealias | Struct | Class | Enum | Protocol | Var | Func
import-path            -> import-path-identifier import-path-tail?
import-path-tail       -> Dot import-path
import-path-identifier -> Identifier | PrefixOperator | BinaryOperator | PostfixOperator
```

#### Constant declaration, Variable declaration

```
module-constant-declaration -> Let variable-name type-annotation

module-variable-declaration -> Var variable-name type-annotation getter-setter-keyword-block

getter-setter-keyword-block -> LeftBrace getter-keyword-clause setter-keyword-clause? RightBrace
                             | LeftBrace setter-keyword-clause getter-keyword-clause RightBrace
getter-keyword-clause       -> attributes? Get
setter-keyword-clause       -> attributes? Set

constant-declaration -> Let pattern-initializer-list

variable-declaration       -> Var pattern-initializer-list
                            | Var variable-name type-annotation variable-declaration-block
                            | Var variable-name initializer willSet-didSet-block
variable-declaration-block -> procedure-block
                            | getter-setter-block
                            | initializer? willSet-didSet-block
variable-name              -> Identifier

getter-setter-block -> LeftBrace getter-clause setter-clause? RightBrace
                     | LeftBrace setter-clause getter-clause RightBrace
getter-clause       -> attributes? Get procedure-block
setter-clause       -> attributes? Set setter-name? procedure-block
setter-name         -> LeftParenthesis Identifier RightParenthesis

willSet-didSet-block -> LeftBrace willSet-clause didSet-clause? RightBrace
                      | LeftBrace didSet-clause willSet-clause? RightBrace
willSet-clause       -> attributes? WillSet setter-name? procedure-block
didSet-clause        -> attributes? DidSet setter-name? procedure-block

pattern-initializer-list -> pattern-initializer pattern-initializer-tail?
pattern-initializer-tail -> Comma pattern-initializer-list
pattern-initializer      -> declarative-pattern type-annotation? initializer?
initializer              -> AssignmentOperator expression
```

#### Typealias declaration

```
associated-type-declaration -> Typealias typealias-name type-inheritance-clause? typealias-assignment?

typealias-declaration -> Typealias typealias-name typealias-assignment
typealias-name        -> Identifier
typealias-assignment  -> AssignmentOperator type
```

#### Function declaration

```
module-function-declaration -> Func function-name generic-parameter-clause? function-signature

function-declaration -> Func function-name generic-parameter-clause? function-signature function-body

function-name      -> Identifier | PrefixOperator | PostfixOperator | BinaryOperator
function-signature -> parameter-clauses (Throws | Rethrows)? function-result?
function-result    -> Arrow attributes? type
function-body      -> procedure-block

parameter-clauses       -> parameter-clause parameter-clauses?
parameter-clause        -> LeftParenthesis RightParenthesis
                         | LeftParenthesis parameter-list RightParenthesis
parameter-list          -> parameter parameter-list-tail?
parameter-list-tail     -> Comma parameter-list
parameter               -> (Let | Var)? external-parameter-name? local-parameter-name type-annotation default-argument-clause?
                         | Inout external-parameter-name? local-parameter-name type-annotation 
                         | external-parameter-name? local-parameter-name type-annotation VariadicSymbol
external-parameter-name -> Identifier | Underscore
local-parameter-name    -> Identifier | Underscore
default-argument-clause -> AssignmentOperator expression
```

#### Enum declaration

```
enum-declaration -> union-style-enum
                  | raw-value-style-enum

union-style-enum         -> Indirect? Enum Identifier generic-parameter-clause? type-inheritance-clause? LeftBrace union-style-enum-members? RightBrace
union-style-enum-members -> union-style-enum-member union-style-enum-members?
union-style-enum-member  -> declaration
                          | module-declaration
                          | union-style-enum-case-clause

union-style-enum-case-clause -> attributes? Indirect? Case union-style-enum-case-list
union-style-enum-case-list   -> union-style-enum-case union-style-enum-case-tail?
union-style-enum-case-tail   -> Comma union-style-enum-case-list
union-style-enum-case        -> enum-case-name tuple-type?

raw-value-style-enum         -> Enum Identifier generic-parameter-clause? type-inheritance-clause LeftBrace raw-value-style-enum-members RightBrace
raw-value-style-enum-members -> raw-value-style-enum-member raw-value-style-enum-members?
raw-value-style-enum-member  -> declaration
                              | raw-value-style-enum-case-clause

raw-value-style-enum-case-clause -> attributes? Case raw-value-style-enum-case-list
raw-value-style-enum-case-list   -> raw-value-style-enum-case raw-value-style-enum-case-tail?
                                  | raw-value-style-module-enum-case raw-value-style-module-enum-case-tail

raw-value-style-module-enum-case-tail -> Comma raw-value-style-module-enum-case-list
raw-value-style-module-enum-case      -> enum-case-name

raw-value-style-enum-case-tail   -> Comma raw-value-style-enum-case-list
raw-value-style-enum-case        -> enum-case-name raw-value-assignment?
raw-value-assignment             -> AssignmentOperator raw-value-literal
raw-value-literal                -> numeric-literal
                                  | StringLiteral

enum-case-name -> Identifier
```

#### Struct declaration

```
module-struct-declaration -> Struct Identifier generic-parameter-clause? type-inheritance-clause? module-struct-body
module-struct-body        -> LeftBrace module-declarations RightBrace

struct-declaration -> Struct Identifier generic-parameter-clause? type-inheritance-clause? struct-body
struct-body        -> LeftBrace declarations? RightBrace
```

#### Class declaration

```
module-class-declaration -> Class Identifier generic-parameter-clause? type-inheritance-clause? module-class-body
module-class-body        -> LeftBrace module-declarations? RightBrace

class-declaration -> Class Identifier generic-parameter-clause? type-inheritance-clause? class-body
class-body        -> LeftBrace declarations? RightBrace
```

#### Protocol declaration

```
protocol-declaration -> Protocol Identifier type-inheritance-clause? protocol-body
protocol-body        -> LeftBrace protocol-member-declarations? RightBrace

protocol-member-declarations -> protocol-member-declaration protocol-declarations?
protocol-member-declaration  -> attributes? declaration-modifiers? module-variable-declaration
                              | attributes? access-level-modifier? associated-type-declaration
                              | attributes? declaration-modifiers? module-function-declaration
                              | attributes? declaration-modifiers? module-initializer-declaration
                              | attributes? declaration-modifiers? module-subscript-declaration
```

#### Initializer declaration

```
module-initializer-declaration -> Init generic-parameter-clause? parameter-clause

initializer-declaration -> Init (PostfixQuestion | PostfixExclamation)? generic-parameter-clause? parameter-clause procedure-block
```

#### Deinitializer declaration

```
deinitializer-declaration -> Deinit procedure-block
```

#### Subscript declaration

```
module-subscript-declaration -> Subscript subscript-result getter-setter-keyword-block

subscript-declaration -> subscript-head subscript-result procedure-block
                       | subscript-head subscript-result getter-setter-block
subscript-head        -> Subscript parameter-clause
subscript-result      -> Arrow attributes? type
```

#### Extension declaration

```
module-extension-declaration -> Extension type-identifier type-inheritance-clause? module-extension-body
module-extension-body        -> Leftbrace module-declarations RightBrace

extension-declaration -> Extension type-identifier type-inheritance-clause? extension-body
extension-body        -> Leftbrace declarations RightBrace
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
                            | associativity-clause? precedence-clause?
precedence-clause          -> Precedence precedence-level
precedence-level           -> DecimalDigits(0...255)
associativity-clause       -> Associativity associativity
associativity              -> Left | Right | None
```
