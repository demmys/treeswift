import Util
import Parser
import Generator

class Indent {
    var indent = ""
    var depth = 0 {
        willSet(d) {
            indent = ""
            for var i = 0; i < d; ++i {
                indent += "  "
            }
        }
    }
}

func prettyPrint(target: CustomStringConvertible) {
    let indent = Indent()
    var lastIndentedDepth = 0
    for (i, c) in target.description.characters.enumerate() {
        switch c {
        case "(", "[":
            if i == 0 {
                print(c, appendNewline: false)
            } else {
                lastIndentedDepth = ++indent.depth
                print("\n\(indent.indent)\(c)", appendNewline: false)
            }
        case ")", "]":
            if lastIndentedDepth == indent.depth {
                print(c, appendNewline: false)
            } else {
                print("\n\(indent.indent)\(c)", appendNewline: false)
            }
            --indent.depth
        default:
            print(c, appendNewline: false)
        }
    }
    print("")
}

let arguments = Process.arguments
if arguments.count < 2 {
    ErrorMessage.NoInputFile.print(Process.arguments[0])
} else {
    let parser = Parser(Array(arguments[1..<arguments.count]))
    switch parser.parse() {
    case let .Succeeded(result):
        for (fileName, exp) in result {
            print("----- \(fileName) -----")
            prettyPrint(exp)
        }
    case let .Failed(errors):
        for error in errors {
            print(error)
        }
    }
}
