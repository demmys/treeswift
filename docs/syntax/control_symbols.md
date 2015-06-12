### IgnoredSymbol

```
IgnoredSymbol -> space
               | line-comment
               | block-comment

space -> '[ \t\0\r\u{000b}\u{000c}]'

block-comment -> '/\*.*' block-comment? '.*\*/'

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
