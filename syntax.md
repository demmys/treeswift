# Non terminal symbol

### Top level decralation

```
top-level-declaration -> statements?
```

### Statements

```
statements -> statement statements?

statement -> expression (LineFeed | Semicolon | EndOfFile)
```

### Expressions

```
expression -> prefix-expression binary-expressions

binary-expressions -> binary-expression binary-expressions?
binary-expression  -> BinaryOperator prefix-expression

prefix-expression -> PrefixOperator? postfix-expression

postfix-expression      -> primary-expression postfix-expression-tail?
postfix-expression-tail -> PostfixOperator postfix-expression-tail?

primary-expression -> literal-expression
                    | LeftParenthesis expression RightParethesis

literal-expression -> literal
```

### Literals

```
literal -> IntegerLiteral
```


# Terminal symbol

### IgnoredSymbol

```
IgnoredSymbol -> space
               | line-comment
               | block-comment

space -> '[ \t\0\r\u{000b}\u{000c}]'

block-comment -> '/\*.*' block-comment '.*\*/'

line-comment -> '//.*' \ze [LineFeed|EndOfFile]
```

### EndOfFile

```
EndOfFile -> 'EOF'
```

### LineFeed

```
LineFeed -> '\n'
```

### Semicolon

```
Semicolon -> ';'
```

### LeftParenthesis, RightParethesis

```
LeftParenthesis -> '('

Rightparethesis -> ')'
```

### IntegerLiteral

```
IntegerLiteral  -> integer-literal

integer-literal -> binary-literal
                 | octal-literal
                 | decimal-literal
                 | hexadecimal-literal

binary-literal      -> '0b[01][01_]*'
octal-literal       -> '0o[0-7][0-7_]*'
decimal-literal     -> '[0-9][0-9_]*'
hexadecimal-literal -> '0x[0-9a-f][0-9a-f_]*'
```

### BinaryOperator, PrefixOperator, PostfixOperator

```
BinaryOperator -> front-separator \zs operator \ze back-separator
                | [^front-separator] \zs operator \ze [^back-separator]

PrefixOperator -> front-separator \zs operator \ze [^back-separator]

PostfixOperator -> [^front-separator] operator \ze back-separator

separator       = Space | LineFeed | Semicolon | EndOfFile]
front-separator = separator | LeftParenthesis
back-separator  = separator | Rightparethesis

operator -> operator-head operator-character*
          | '..' ['.'|operator-character]*

operator-head  -> '[/=-+!*%<>&|^?~
                   \u{00a1}-\u{00a7}
                   \u{00a9}
                   \u{00ab}
                   \u{00ac}
                   \u{00ae}
                   \u{00b0}
                   \u{00b1}
                   \u{00b6}
                   \u{00bb}
                   \u{00bf}
                   \u{00d7}
                   \u{00f7}
                   \u{2016}
                   \u{2017}
                   \u{2020}-\u{2027}
                   \u{2030}-\u{203e}
                   \u{2041}-\u{2053}
                   \u{2055}-\u{205e}
                   \u{2190}-\u{23ff}
                   \u{2500}-\u{2775}
                   \u{2794}-\u{2bff}
                   \u{2e00}-\u{2e7f}
                   \u{3001}-\u{3003}
                   \u{3008}-\u{3030}
                  ]'

operator-character -> operator-head
                    | '[
                       \u{0300}-\u{036f}
                       \u{1dc0}-\u{1dff}
                       \u{20d0}-\u{20ff}
                       \u{fe00}-\u{fe0f}
                       \u{fe20}-\u{fe2f}
                       \u{e0100}-\u{e01ef}
                      ]'
```
