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
                print(c, terminator: "")
            } else {
                lastIndentedDepth = ++indent.depth
                print("\n\(indent.indent)\(c)", terminator: "")
            }
        case ")", "]":
            if lastIndentedDepth == indent.depth {
                print(c, terminator: "")
            } else {
                print("\n\(indent.indent)\(c)", terminator: "")
            }
            --indent.depth
        default:
            print(c, terminator: "")
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
        for (fileName, ps) in result {
            print("----- \(fileName) -----")
            for p in ps {
                prettyPrint(p)
            }
        }
    case let .Failed(errors):
        for (msg, info) in errors {
            if let i = info {
                print("\(i.lineNo):\(i.charNo) \(msg)\n\(i.source!)")
            } else {
                print("\(msg)")
            }
        }
    }
}
