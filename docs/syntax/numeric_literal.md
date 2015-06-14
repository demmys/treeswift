### Numeric literal

```
numeric-literal -> PrefixHyphen? IntegerLiteral
                 | PrefixHyphen? FloatingPointLiteral

DecimalDigits -> '[0-9]+'
HexadecimalDigits -> '[0-9a-f]+'

binary-literal      -> '0b[01][01_]*'
octal-literal       -> '0o[0-7][0-7_]*'
decimal-literal     -> '[0-9][0-9_]*'
hexadecimal-literal -> '0x[0-9a-fA-F][0-9a-fA-F_]*'
```

#### IntegerLiteral

```
IntegerLiteral  -> integer-literal

integer-literal -> binary-literal
                 | octal-literal
                 | decimal-literal
                 | hexadecimal-literal
```

#### Floating point literal

```
FloatingPointLiteral -> decimal-literal decimal-fraction? decimal-exponent?
                      | hexadecimal-literal hexadecimal-fraction? hexadecimal-exponent

decimal-fraction -> '\.[0-9][0-9_]*'
decimal-exponent -> floating-point-e sign? '[0-9][0-9_]*'

hexadecimal-fraction -> '\.[0-9a-fA-F][0-9a-fA-F_]*'
hexadecimal-exponent -> floating-point-p sign? '[0-9a-fA-F][0-9a-fA-F_]*'

floating-point-e -> 'e' | 'E'
floating-point-p -> 'p' | 'P'

sign -> '+' | '-'
```
