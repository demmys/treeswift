### Literals

```
literal -> numeric-literal
         | StringLiteral
         | BooleanLiteral
         | Nil
```

#### Numeric literal

```
numeric-literal -> Minus? IntegerLiteral
                 | Minus? FloatingPointLiteral

DecimalDigits -> '[0-9]+'

binary-literal      -> '0b[01][01_]*'
octal-literal       -> '0o[0-7][0-7_]*'
decimal-literal     -> '[0-9][0-9_]*'
hexadecimal-literal -> '0x[0-9a-fA-F][0-9a-fA-F_]*'

IntegerLiteral  -> integer-literal

integer-literal -> binary-literal
                 | octal-literal
                 | decimal-literal
                 | hexadecimal-literal

FloatingPointLiteral -> decimal-literal decimal-fraction? decimal-exponent?
                      | hexadecimal-literal hexadecimal-fraction? hexadecimal-exponent

decimal-fraction -> '\.[0-9][0-9_]*'
decimal-exponent -> '[eE]' sign? '[0-9][0-9_]*'

hexadecimal-fraction -> '\.[0-9a-fA-F][0-9a-fA-F_]*'
hexadecimal-exponent -> '[pP]' sign? '[0-9][0-9_]*'

sign -> '+' | '-'
```

#### String literal

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

#### BooleanLiteral

```
BooleanLiteral -> "true" | "false"
```
