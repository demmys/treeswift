func debugInformation(token: Token) -> String {
    return "(\(token.lineNo):\(token.charNo): \(token.source)"
}

func parse(file: File) {
    if let parser = Parser(file) {
        if parser.parse() {
            println("Accepted.")
        } else {
            parser.errors.map({ $0.print(file.name) })
        }
    }
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
            case .Semicolon:
                println("Semicolon")
            case .EndOfFile:
                endOfFile = true
            case let .IntegerLiteral(x):
                println("IntegerLiteral: \(x)")
            case let .Operator(x):
                println("Operator: \(x)")
            case let .Error(i):
                i.print(file.name, lineNo: t.lineNo, charNo: t.charNo, source: t.source)
            }
        }
    } else {
        ErrorInfo(reason: "The file is not a textfile").print(file.name)
    }
}

if Process.arguments.count < 2 {
    ErrorInfo(reason: "No input files").print(Process.arguments[0])
} else {
    let file = File(name: Process.arguments[1], mode: "r")
    if let f = file {
        parse(f);
    } else {
        ErrorInfo(reason: "File not found").print(Process.arguments[0])
    }
}
