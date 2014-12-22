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
            case .EndOfFile:
                endOfFile = true
            case .Semicolon:
                println(";")
            case .Colon:
                println(":")
            case .Comma:
                println(",")
            case .Arrow:
                println("->")
            case .Hash:
                println("#")
            case .Underscore:
                println("_")
            case .PrefixLessThan:
                println("Prefix: <")
            case .PostfixGraterThan:
                println("Postfix: >")
            case .PrefixAmpersand:
                println("Prefix: &")
            case .PrefixQuestion:
                println("Prefix: ?")
            case .BinaryQuestion:
                println("Binary: ?")
            case .PostfixQuestion:
                println("Postfix: ?")
            case .PostfixExclamation:
                println("Postfix: !")
            case .Dot:
                println(".")
            case .LeftParenthesis:
                println("(")
            case .RightParenthesis:
                println(")")
            case .LeftBrace:
                println("{")
            case .RightBrace:
                println("}")
            case .LeftBracket:
                println("[")
            case .RightBracket:
                println("]")
            case let .Identifier(kind):
                switch kind {
                case let .Identifier(x):
                    println("Identifier: \(x)")
                case let .QuotedIdentifier(x):
                    println("QuotedIdentifier: `\(x)`")
                case let .ImplicitParameter(x):
                    println("ImplicitParameter: $\(x)")
                }
            case let .IntegerLiteral(x):
                println("IntegerLiteral: \(x)")
            case .AssignmentOperator:
                println("=")
            case let .BinaryOperator(x):
                println("BinaryOperator: \(x)")
            case let .PrefixOperator(x):
                println("PrefixOperator: \(x)")
            case let .PostfixOperator(x):
                println("PostfixOperator: \(x)")
            case .For:
                println("for")
            case .While:
                println("while")
            case .Do:
                println("do")
            case .If:
                println("if")
            case .Else:
                println("else")
            case .Break:
                println("break")
            case .Continue:
                println("continue")
            case .Return:
                println("return")
            case .Let:
                println("let")
            case .Var:
                println("var")
            case .Func:
                println("func")
            case .Inout:
                println("inout")
            case .Prefix:
                println("prefix")
            case .Postfix:
                println("postfix")
            case .Infix:
                println("infix")
            case .Operator:
                println("operator")
            case .Precedence:
                println("precedence")
            case .Associativity:
                println("associativity")
            case .Left:
                println("left")
            case .Right:
                println("right")
            case .None:
                println("none")
            case .Is:
                println("is")
            case .As:
                println("as")
            case .In:
                println("in")
            case .Typealias:
                println("typealias")
            case let .Error(m):
                m.print(file.name, info: t.info)
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
        lex(f);
    } else {
        ErrorMessage.FileNotFound.print(Process.arguments[0])
    }
}
