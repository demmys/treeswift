import Util
import Parser
import Generator

if Process.arguments.count < 2 {
    ErrorMessage.NoInputFile.print(Process.arguments[0])
} else {
    let file = File(name: Process.arguments[1], mode: "r")
    if let f = file {
        if let parser = Parser(f) {
            switch parser.parse() {
            case let .Success(ast):
                Generator.print(
                    Generator.generate(ast, moduleID: "-"),
                    fileName: f.baseName + ".ll"
                )
            case let .Failure(errors):
                for (message, info) in errors {
                    message.print(f.name, info: info)
                }
            }
        }
    } else {
        ErrorMessage.FileNotFound.print(Process.arguments[0])
    }
}
