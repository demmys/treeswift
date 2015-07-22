### Procedures

```
procedures -> procedure procedures?

procedure -> procedure-head (LineFeed | Semicolon | EndOfFile)
procedure-head -> declaration
                | operation
                | flow

procedure-block -> LeftBrace procedures? RightBrace
```

### Flows

```
flow -> loop-flow
      | branch-flow
      | labeled-flow
      | defer-flow
      | do-flow
```

#### Loop flow

```
loop-flow -> for-flow
           | for-in-flow
           | while-flow
           | repeat-while-flow

for-flow -> For for-flow-setting procedure-block
          | For LeftParenthesis for-flow-pattern RightParenthesis procedures-block

/* for-flow accepts boolean pattern only */
for-flow-setting -> for-init? Semicolon expression Semicolon for-finalize
for-init         -> variable-declaration
                  | expression
                  | assignment-operation
for-finalize     -> operation \ze LeftBrace

for-in-flow    -> For for-in-pattern In expression condition-clause procedure-block
for-in-pattern -> declarational-pattern
                | Case conditional-pattern

while-flow    -> While pattern-match-clause procedures-block

/* repeat-while-flow accepts boolean pattern only */
repeat-while-flow -> Repeat procedure-block While expression
```

#### Branch flow

```
branch-flow -> if-flow
             | guard-flow
             | switch-flow

if-flow     -> If pattern-match-clause procedure-block else-clause?
else-clause -> Else procedure-block
             | Else if-flow

guard-flow -> Guard pattern-match-clause Else procedure-block

switch-flow         -> Switch expression LeftBrace switch-cases? RightBrace
switch-cases        -> switch-case switch-cases
switch-case         -> case-label procedures
                     | case-label Semicolon
                     | Default Colon procedures
                     | Default Colon Semicolon
case-label          -> Case case-item-list Colon
case-item-list      -> conditional-pattern condition-clause? case-item-list-tail?
case-item-list-tail -> Comma case-item-list
```

#### Pattern match clause

```
pattern-match-clause -> expression /* boolean pattern */
                      | expression Comma pattern-list
                      | pattern-list

pattern-list      -> matching-pattern pattern-list-tail?
pattern-list-tail -> Comma pattern-list
matching-pattern  -> optional-binding-pattern-list
                   | case-pattern

optional-binding-pattern-list         -> optional-binding optional-binding-pattern-list-tail? condition-clause?
optional-binding                      -> Let optional-binding-body
                                       | Var optional-binding-body
optional-binding-body                 -> declarational-pattern AssignmentOperator expression
optional-binding-pattern-list-tail    -> Comma optional-binding-pattern-continuation optional-binding-pattern-list-tail?
optional-binding-pattern-continuation -> optional-binding
                                       | optional-binding-body

case-pattern -> Case conditional-pattern AssignmentOperator expression condition-clause
```

#### Labeled flow

```
labeled-statement -> flow-label loop-flow
                   | flow-label if-flow
                   | flow-label switch-label
flow-label        -> Identifier Colon
```

#### Defer flow

```
defer-flow -> Defer procedure-block
```

#### Do flow

```
do-flow       -> Do procedure-block catch-clauses?
catch-clauses -> catch-clause catch-clauses?
catch-clause  -> Catch conditional-pattern? condition-clause? procedure-block
```
