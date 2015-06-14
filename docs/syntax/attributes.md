### Attributes

```
attributes                -> attribute attributes
attribute                 -> Atmark Identifier attribute-argument-clause?
attribute-argument-clause -> LeftParenthesis balanced-tokens? RightParenthesis

balanced-tokens -> balanced-token balanced-tokens
balanced-token  -> LeftParenthesis balanced-tokens? LeftParenthesis
                 | LeftBracket balanced-tokens? LeftBracket
                 | LeftBrace balanced-tokens? LeftBrace
                 | '[^ ()[\]{}]+'
```
