func debugInformation(token: Token) -> String {
    return "(\(token.lineNo):\(token.charNo): \(token.source)"
}

func lex(file: File) {
    if let stream = TokenStream(file) {
        var endOfFile = false
        for var t = stream.look(); !endOfFile; stream.next(), t = stream.look() {
            switch t.kind! {
            case .Space:
                println("Space")
            case .LineFeed:
                println("LineFeed")
            case .EndOfFile:
                endOfFile = true
            case let .IntegerLiteral(x):
                println("IntegerLiteral: \(x)")
            case let .Operator(x):
                println("Operator: \(x)")
            case let .Error(i):
                i.print(t.lineNo, charNo: t.charNo, source: t.source)
            }
        }
    } else {
        ErrorInfo(target: file.name, reason: "The file is not a textfile").print()
    }
}

if Process.arguments.count < 2 {
    ErrorInfo(target: Process.arguments[0], reason: "No input files").print()
} else {
    let file = File(name: Process.arguments[1], mode: "r")
    if let f = file {
        lex(f);
    } else {
        ErrorInfo(target: Process.arguments[0], reason: "File not found").print()
    }
}
