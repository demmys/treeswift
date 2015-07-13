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
                | defer-statement
                | do-statement
```

#### Loop statement

```
loop-statement -> for-statement
                | for-in-statement
                | while-statement
                | repeat-while-statement

for-statement    -> For for-condition code-block
                  | For LeftParenthesis for-condition RightParenthesis code-block
for-condition    -> for-init? Semicolon for-confirmation? Semicolon for-finalize?
for-init         -> variable-declaration
                  | expression-list
for-confirmation -> expression \ze ^Semicolon
for-finalize -> expression \ze ^LeftBrace

for-in-statement -> For Case? pattern In expression where-clause? code-block

while-statement  -> While condition-clause code-block

repeat-while-statement -> Repeat code-block While expression
```

#### Branch statement

```
branch-statement -> if-statement
                  | guard-statement
                  | switch-statement

if-statement -> If condition-clause code-block else-clause?
else-clause  -> Else code-block
              | Else if-statement

guard-statement -> Guard condition-clause Else code-block

switch-statement -> Switch expression LeftBrace switch-cases? RightBrace

switch-cases -> switch-case switch-cases?
switch-case -> case-label statements
             | default-label statements
             | case-label Semicolon
             | default-label Semicolon

case-label -> Case case-item-list Colon
case-item-list -> pattern where-clause? case-item-list-tail?
case-item-list-tail -> Comma case-item-list
default-label -> Default Colon
```

#### Condition clause

```
condition-clause    -> expression
                     | expression Comma condition-list
                     | condition-list
                     // | availability-condition Comma expression
condition-list      -> condition condition-list-tail?
condition-list-tail -> Comma condition-list
condition           -> case-condition
                     | optional-binding-condition
                     // | availability-condition

case-condition -> Case pattern initializer where-clause?

optional-binding-condition         -> optional-binding-head optional-binding-continuation-list? where-clause?
optional-binding-head              -> Let pattern initializer
                                    | Var pattern initializer
optional-binding-continuation-list -> Comma optional-binding-continuation optional-binding-continuation-tail?
optional-binding-continuation-tail -> optional-binding-continuation-list
optional-binding-continuation      -> pattern initializer
                                    | optional-binding-head

where-clause     -> Where where-expression
where-expression -> expression
```

#### Labeled statement

```
labeled-statement -> statement-label loop-statement
                   | statement-label if-statement
                   | statement-label switch-statement
statement-label   -> label-name Colon
label-name        -> Identifier
```

#### Control transfer statement

```
control-transfer-statement -> break-statement
                            | continue-statement
                            | fallthrough-statement
                            | return-statement
                            | throw-statement

break-statement -> Break label-name?

continue-statement -> Continue label-name?

fallthrough-statement -> Fallthrough

return-statement -> Return
                  | Return expression

throw-statement -> Throw expression
```

#### Defer statement

```
defer-statement -> Defer code-block
```

#### Do statement

```
do-statement  -> Do code-block catch-clauses?
catch-clauses -> catch-clause catch-clauses?
catch-clause  -> Catch pattern? where-clause? code-block
```
