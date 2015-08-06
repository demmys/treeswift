### Attributes

```
attributes                -> attribute attributes
attribute                 -> Atmark Identifier // attribute-argument-clause?
attribute-argument-clause -> LeftParenthesis balanced-tokens? RightParenthesis

balanced-tokens -> balanced-token balanced-tokens
balanced-token  -> LeftParenthesis balanced-tokens? LeftParenthesis
                 | LeftBracket balanced-tokens? LeftBracket
                 | LeftBrace balanced-tokens? LeftBrace
                 | '[^ ()[\]{}]+'
```

#### Modifiers

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
