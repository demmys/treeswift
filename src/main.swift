if Process.arguments.count < 2 {
    println("no input files")
} else {
    let file = File(name: Process.arguments[1], mode: "r")
    if let f = file {
        if let stream = TokenStream(f) {
            while true {
                if let token = stream.next() {
                    switch token.kind! {
                    case let .IntegerLiteral(x):
                        println("IntegerLiteral: \(x)")
                    }
                } else {
                    break
                }
            }
        } else {
            println("the file is not a textfile")
        }
    } else {
        println("file not found")
    }
}
