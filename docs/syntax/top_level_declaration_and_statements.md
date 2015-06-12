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
for-condition    -> for-init? Semicolon for-confirmation? Semicolon for-finalize?
for-init         -> variable-declaration
                  | expression-list
for-confirmation -> expression \ze ^Semicolon
for-finalize -> expression \ze ^LeftBrace

for-in-statement -> For pattern In expression code-block

while-statement -> While while-condition code-block
while-condition -> expression
                 | declaration

do-while-statement -> Do code-block While while-condition
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
