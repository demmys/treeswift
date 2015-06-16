import Util
import Parser
import Generator

let arguments = Process.arguments
if arguments.count < 2 {
    ErrorMessage.NoInputFile.print(Process.arguments[0])
} else {
    let parser = Parser(Array(arguments[1..<arguments.count]))
    switch parser.parse() {
    case let .TokensOfFiles(result):
        for (fileName, tokens) in result {
            print("----- \(fileName) -----")
            for token in tokens {
                print(token.kind)
            }
        }
    case let .Error(errors):
        for error in errors {
            print(error)
        }
    }
}
