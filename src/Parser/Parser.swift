import Util

private enum ParserError : ErrorType {
    case FileNotFound(String)
    case FileCanNotRead(String)
}

public enum ParseResult {
    case TokensOfFiles([String:[Token]])
    case Error([String])
}

public class Parser {
    private let fileNames: [String]

    public init(_ fileNames: [String]) {
        self.fileNames = fileNames
    }

    public func parse() -> ParseResult {
        var result: [String:[Token]] = [:]
        for fileName in fileNames {
            do {
                let ts = try createStream(fileName)
                result[fileName] = parseTokens(ts)
            } catch ParserError.FileNotFound(let name) {
                return .Error(["No such a file: \(name)"])
            } catch ParserError.FileCanNotRead(let name) {
                return .Error(["File cannot read: \(name)"])
            } catch let e {
                return .Error(["Unexpected error: \(e)"])
            }
        }
        return .TokensOfFiles(result)
    }

    private func createStream(fileName: String) throws -> TokenStream {
        guard let f = File(name: fileName, mode: "r") else {
            throw ParserError.FileNotFound(fileName)
        }
        guard let ts = TokenStream(file: f) else {
            throw ParserError.FileCanNotRead(fileName)
        }
        return ts
    }

    private func parseTokens(ts: TokenStream) -> [Token] {
        var tokens: [Token] = []
        repeat {
            tokens.append(ts.look())
            ts.next()
        } while tokens.last!.kind != .EndOfFile
        return tokens
    }
}
