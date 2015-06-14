### String literal

```
StringLiteral -> '"' quoted-text? '"'

quoted-text -> quoted-text-item quoted-text?
quoted-text-item -> escaped-character
                  | '\\(' expression '\\)'
                  | '[^"\\\u{000A}\u{000D}]+'
escaped-character -> '\\0' | '\\\\' | '\\t' | '\\n' | '\\r' | '\\"' | '\\\''
                   | '\\u\{[0-9a-fA-F]{1, 8}'
```
