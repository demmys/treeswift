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

func modulePaths(parseOptions: [CompilerOption]) -> [String:String] {
    let includes = parseOptions.map({ o -> String in
        if case let .IncludePath(path) = o {
            return path
        }
        return ""
    }).filter({ !$0.isEmpty })
    var modules: [String:String] = [:]
    for i in includes {
        guard let dir = Dir(name: i) else {
            continue
        }
        let fileNames = dir.read().filter({ $0.hasSuffix(".tsm") })
        modules = fileNames.reduce(modules, combine: { (var ms, f) -> [String:String] in
            ms[String(f.characters.dropLast(4))] = "\(i)/\(f)"
            return ms
        })
    }
    return modules
}

func moduleName(parseOptions: [CompilerOption]) -> String {
    var name = "-"
    for o in parseOptions {
        if case let .ModuleName(n) = o {
            name = n
        }
    }
    return name
}

func printParseResult(parseResult: [String:TopLevelDeclaration]) {
    for (fileName, tld) in parseResult {
        print("----- \(fileName) -----")
        for p in tld.procedures {
            prettyPrint(p)
        }
    }
}

let optionParser = OptionParser<CompilerOption>()
optionParser.setOption(
    "I", { (arg) in CompilerOption.IncludePath(arg!) }, requireArgument: true
)
optionParser.setOption(
    "L", { (arg) in CompilerOption.LibraryPath(arg!) }, requireArgument: true
)
optionParser.setOption(
    "module-name", { (arg) in CompilerOption.ModuleName(arg!) }, requireArgument: true
)

do {
    let (result: parseOptions, remains: arguments) = try optionParser.parse()
    if arguments.count < 2 {
        printError("No input file.")
    } else {
        do {
            let modules = modulePaths(parseOptions)
            let parser = Parser(moduleName: moduleName(parseOptions), modules: modules)
            let result = try parser.parse(Array(arguments.dropFirst(1)))
            ErrorReporter.report()
            printParseResult(result)
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
