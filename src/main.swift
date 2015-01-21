import Util
import Parser

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
