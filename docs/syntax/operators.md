### Operators

```
BinaryDoubleEqual = '=='

BinaryOperator -> front-separator \zs operator \ze back-separator
                | [^front-separator] \zs operator \ze [^back-separator]
                | dot-front-separator \zs dot-operator \ze dot-back-separator
                | [^dot-front-separator] \zs dot-operator \ze [^dot-back-separator]

PrefixOperator -> front-separator \zs operator \ze [^back-separator]
                | dot-front-separator \zs dot-operator \ze [^dot-back-separator]

PostfixOperator -> [^front-separator] operator \ze back-separator
                 | [^dot-front-separator] dot-operator \ze dot-back-separator

front-separator     = default-separator | LeftParenthesis
dot-front-separator = separator | LeftParenthesis
back-separator      = default-separator | RightParenthesis
dot-back-separator  = separator | RightParenthesis
default-separator   = separator | Dot
separator           = Space | EndOfFile | LineFeed | Semicolon | Colon | Comma

operator     -> operator-head operator-character*
dot-operator -> '..' ['.'|operator-character]*

operator-head      -> '[/=-+!*%<>&|^?~
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
