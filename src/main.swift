func debugInformation(token: Token) -> String {
    return "(\(token.lineNo):\(token.charNo): \(token.source)"
}

func parse(file: File) {
    if let parser = Parser(file) {
        switch parser.parse() {
        case .Success:
            println("Accepted.")
        case let .Failure(errors):
            for (message, info) in errors {
                message.print(file.name, info: info)
            }
        }
    }
}

func lex(file: File) {
    if let stream = TokenStream(file) {
        var endOfFile = false
        for var t = stream.look(); !endOfFile; stream.next(), t = stream.look() {
            switch t.kind {
            case .LineFeed:
                println("LineFeed")
            case .Semicolon:
                println("Semicolon")
            case .EndOfFile:
                endOfFile = true
            case let .IntegerLiteral(x):
                println("IntegerLiteral: \(x)")
            case let .BinaryOperator(x):
                println("BinaryOperator: \(x)")
            case let .PrefixOperator(x):
                println("PrefixOperator: \(x)")
            case let .PostfixOperator(x):
                println("PostfixOperator: \(x)")
            case .LeftParenthesis:
                println("LeftParenthesis")
            case .RightParenthesis:
                println("RightParenthesis")
            case let .Error(m):
                m.print(file.name, info: t.info)
            default:
                println("!!!!!!! Unexpected Token !!!!!!!")
            }
        }
    } else {
        ErrorMessage.InvalidFileType.print(file.name)
    }
}

if Process.arguments.count < 2 {
    ErrorMessage.NoInputFile.print(Process.arguments[0])
} else {
    let file = File(name: Process.arguments[1], mode: "r")
    if let f = file {
        parse(f);
    } else {
        ErrorMessage.FileNotFound.print(Process.arguments[0])
    }
}
