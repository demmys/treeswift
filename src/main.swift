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
    print("No input file")
} else {
    let parser = Parser(Array(arguments[1..<arguments.count]))
    do {
        let result = try parser.parse()
        ErrorReporter.report()
        for (fileName, tld) in result {
            print("----- \(fileName) -----")
            for p in tld.procedures {
                prettyPrint(p)
            }
        }
    } catch ErrorReport.Fatal {
        print("Compile process aborted because of the fatal error.")
        ErrorReporter.report()
    } catch ErrorReport.Full {
        print("Compile process aborted because of too much errors.")
        ErrorReporter.report()
    } catch ErrorReport.Found {
        print("Some errors found in compile process.")
        ErrorReporter.report()
    } catch let e {
        print("Compile process aborted because of unexpected error.")
        print(e)
    }
}
