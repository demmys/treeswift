### Procedures

```
procedures -> procedure procedures?

procedure -> procedure-head (LineFeed | Semicolon | EndOfFile)
procedure-head -> declaration
                | operation
                | flow
                | flow-switch
                | labeled-procedure

procedure-block -> LeftBrace procedures? RightBrace

labeled-procedure -> procedure-label loop-flow
                   | procedure-label if-flow
                   | procedure-label flow-switch
procedure-label   -> Identifier Colon

restraint -> Where expression
```

### Flows

```
flow -> loop-flow
      | branch-flow
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
          | For LeftParenthesis for-flow-setting RightParenthesis procedures-block

/* for-flow accepts boolean pattern only */
for-flow-setting -> for-init? Semicolon expression? Semicolon for-finalize
for-init         -> variable-declaration
                  | expression
                  | assignment-operation
for-finalize     -> expression
                  | assignment-operation

for-in-flow    -> For for-in-pattern In expression requirement-clause? procedure-block
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

if-flow     -> If pattern-match-clause procedure-block else-clause?
else-clause -> Else procedure-block
             | Else if-flow

guard-flow -> Guard pattern-match-clause Else procedure-block
```

#### Defer flow

```
defer-flow -> Defer procedure-block
```

#### Do flow

```
do-flow       -> Do procedure-block catch-flows?
catch-clauses -> catch-flow catch-flows?
catch-flow  -> Catch conditional-pattern? restraint? procedure-block
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

optional-binding-pattern-list         -> optional-binding optional-binding-pattern-list-tail? restraint?
optional-binding                      -> Let optional-binding-body
                                       | Var optional-binding-body
optional-binding-body                 -> declarational-pattern AssignmentOperator expression
optional-binding-pattern-list-tail    -> Comma optional-binding-body optional-binding-pattern-list-tail?

case-pattern -> Case conditional-pattern AssignmentOperator expression restraint?
```

#### Flow switch
```
flow-switch         -> Switch expression LeftBrace case-flows? RightBrace
case-flows          -> case-flow case-flows
case-flow           -> case-label procedures
                     | case-label Semicolon
                     | Default Colon procedures
                     | Default Colon Semicolon
case-label          -> Case case-item-list Colon
case-item-list      -> conditional-pattern restraint? case-item-list-tail?
case-item-list-tail -> Comma case-item-list
```
