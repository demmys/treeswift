import Util
import AST
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

func printError(message: Any) {
    print("\(Process.arguments[0]): ", terminator: "", toStream: &STDERR)
    print(message, toStream: &STDERR)
}

let optionParser = OptionParser<ParseOption>()
optionParser.setOption("sdk", { (arg) in ParseOption.SDKPath(arg!) }, requireArgument: true)
optionParser.setOption("I", { (arg) in ParseOption.IncludePath(arg!) }, requireArgument: true)
optionParser.setOption("L", { (arg) in ParseOption.LibraryPath(arg!) }, requireArgument: true)
do {
    let (result: parseOptions, remains: arguments) = try optionParser.parse()
    print(parseOptions)
    if arguments.count < 2 {
        printError("No input file.")
    } else {
        let parser = Parser(Array(arguments.dropFirst(1)))
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
            printError("Compile process aborted because of the fatal error.")
            ErrorReporter.report()
        } catch ErrorReport.Full {
            printError("Compile process aborted because of too much errors.")
            ErrorReporter.report()
        } catch ErrorReport.Found {
            printError("Some errors found in compile process.")
            ErrorReporter.report()
        } catch let e {
            printError("Compile process aborted because of unexpected error.")
            printError(e)
        }
    }
} catch let OptionParseError.InvalidOption(option) {
    printError("Invalid option '\(option)'.")
} catch let OptionParseError.ArgumentNotProvided(option) {
    printError("Option '\(option)' needs argument.")
} catch let e {
    printError(e)
}
