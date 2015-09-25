### Operator namng theories

* Symbols in name of operators are converted to alphabetic characters in LLVM function.
* ASCII symbols are converted to initial of its name.
* Other unicode symbols are converted to "u[0-9]+" in regular expression by using its unicode number.

```swift
func encode(operator: (PrefixOperator | PostfixOperator | BinaryOperator)) -> String {
    var result = ""
    var scalars = operator.unicodeScalars
    for var i = scalars.startIndex; i != scalars.endIndex; i = i.successor() {
        result.appendContentsOf(encodeScalar(scalars[i])
    }
    return result
}

private func encodeScalar(s: UnicodeScalar) -> String {
    switch(Character(s)) {
    case "/":
        return "d"
    case "=":
        return "e"
    case "-":
        return "s"
    case "+":
        return "p"
    case "!":
        return "n"
    case "*":
        return "m"
    case "%":
        return "r"
    case "<":
        return "l"
    case ">":
        return "g"
    case "&":
        return "a"
    case "|":
        return "o"
    case "^":
        return "x"
    case "?":
        return "q"
    case "~":
        return "t"
    default:
        return "u" + String(s.value)
    }
}
```

### Operator declaration

operator-declaration -> Prefix Operator BinaryOperator LeftBrace RightBrace
```llvm
; TODO
```

operator-declaration -> Postfix Operator BinaryOperator LeftBrace RightBrace
```llvm
; TODO
```

operator-declaration -> Infix Operator BinaryOperator LeftBrace RightBrace
```llvm
; TODO
```

operator-declaration -> Infix Operator BinaryOperator LeftBrace Precedence DecimalDigits(0...255) RightBrace
```llvm
; TODO
```

operator-declaration -> Infix Operator BinaryOperator LeftBrace Associativity associativity RightBrace
```llvm
; TODO
```

operator-declaration -> Infix Operator BinaryOperator LeftBrace Precedence DecimalDigits(0...255) Associativity associativity RightBrace
```llvm
; TODO
```
