import Util
import AST
import Parser
import TypeInference
import Generator

class Indent {
    var indent = ""
    var depth = 0 {
        didSet(before) {
            if !freeze {
                // change indent
                indent = ""
                for var i = 0; i < depth; ++i {
                    indent += "  "
                }
                // memory indented depth
                if depth > before {
                    lastIndentedDepth = depth
                }
            }
        }
    }
    var lastIndentedDepth = 0
    var nestedLine: Bool {
        return lastIndentedDepth != depth
    }
    var freeze = false
    var newLinePrefix: String {
        if !freeze {
            return "\n\(indent)"
        }
        return ""
    }
}

func prettyPrint(target: CustomStringConvertible) {
    let indent = Indent()
    for (i, c) in target.description.characters.enumerate() {
        switch c {
        case "`":
            indent.freeze = !indent.freeze
        case "(", "[":
            if i == 0 {
                print(c, terminator: "")
            } else {
                ++indent.depth
                print("\(indent.newLinePrefix)\(c)", terminator: "")
            }
        case ")", "]":
            if indent.nestedLine {
                print("\(indent.newLinePrefix)\(c)", terminator: "")
            } else {
                print(c, terminator: "")
            }
            --indent.depth
        default:
            print(c, terminator: "")
        }
    }
    print("")
}

func printParseResult(parseResult: [String:TopLevelDeclaration]) {
    for (fileName, tld) in parseResult {
        print("----- \(fileName) -----")
        prettyPrint(tld)
    }
}

func printModules() {
    for (moduleName, module) in ScopeManager.modules {
        print("----- \(moduleName) -----")
        prettyPrint(module)
    }
}

let commandName = Process.arguments[0]
func printError(message: Any) {
    print("\(commandName): ", terminator: "", toStream: &STDERR)
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
optionParser.setOption(
    "dump-parse", { (arg) in CompilerOption.DumpParse }, requireArgument: false
)
optionParser.setOption(
    "dump-ast", { (arg) in CompilerOption.DumpAST }, requireArgument: false
)

do {
    let (result: parseOptions, remains: arguments) = try optionParser.parse()
    // print("main:parseOptions:\n\t\(parseOptions)") // DEBUG
    // print("main:arguments:\n\t\(arguments)") // DEBUG
    var dumpParseOnly = false
    for option in parseOptions {
        if case .DumpParse = option {
            dumpParseOnly = true
            break
        }
    }
    if arguments.count < 2 {
        printError("No input file.")
    } else {
        do {
            let modules = modulePaths(parseOptions)
            // print("main:modules:\n\t\(modules)") // DEBUG
            let parser = Parser(moduleName: moduleName(parseOptions), modules: modules)
            let result = try parser.parse(Array(arguments.dropFirst(1)), useStdLib: dumpParseOnly)
            ErrorReporter.instance.report()
            if dumpParseOnly {
                printParseResult(result) // DEBUG
                exit(0)
            }
            // ScopeManager.printScopes() // DEBUG
            try ScopeManager.resolveRefs()
            let inferer = TypeInference()
            for (_, mod) in ScopeManager.modules {
                try inferer.visit(mod)
            }
            for (_, tld) in result {
                try inferer.visit(tld)
            }
            // inferer.printConstraints() // DEBUG
            try inferer.infer()
            // printModules() // DEBUG
            for option in parseOptions {
                if case .DumpAST = option {
                    printParseResult(result) // DEBUG
                    break
                }
            }
        } catch ErrorReport.Fatal {
            printError("Compile process aborted because of the fatal error.")
            ErrorReporter.instance.report()
        } catch ErrorReport.Full {
            printError("Compile process aborted because of too much errors.")
            ErrorReporter.instance.report()
        } catch ErrorReport.Found {
            printError("Some errors found in compile process.")
            ErrorReporter.instance.report()
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
