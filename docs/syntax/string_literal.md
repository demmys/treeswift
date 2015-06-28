### String literal

```
StringLiteral -> DoubleQuote quoted-text? DoubleQuote

quoted-text       -> quoted-text-item quoted-text?
quoted-text-item  -> escaped-character
                   | BackSlash LeftParenthesis expression RightParenthesis
                   | '[^"\\\u{000A}\u{000D}]+'
escaped-character -> BackSlash '0'
                   | BackSlash BackSlash
                   | BackSlash 't'
                   | BackSlash 'n'
                   | BackSlash 'r'
                   | BackSlash DoubleQuote
                   | BackSlash '\''
                   | BackSlash 'u' LeftBrace '[0-9a-fA-F]{1, 8}' RightBrace
```
