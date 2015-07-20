import Util

enum ParserError : ErrorType {
    case FileNotFound(String)
    case FileCanNotRead(String)
    case Error(String, SourceInfo)
}

public enum ParseResult {
    case Succeeded([String:Expression])
    case Failed([Error])
}

public class Parser {
    private let fileNames: [String]
    private var ts: TokenStream!

    public init(_ fileNames: [String]) {
        self.fileNames = fileNames
    }

    public func parse() -> ParseResult {
        var result: [String:Expression] = [:]
        for fileName in fileNames {
            do {
                ts = try createStream(fileName)
                result[fileName] = try topLevelDeclaration()
            } catch ParserError.FileNotFound(let name) {
                return .Failed([("No such a file: \(name)", nil)])
            } catch ParserError.FileCanNotRead(let name) {
                return .Failed([("File cannot read: \(name)", nil)])
            } catch ParserError.Error(let s, let i) {
                return .Failed([(s, i)])
            } catch let e {
                return .Failed([("Unexpected error: \(e)", nil)])
            }
        }
        return .Succeeded(result)
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

    private func topLevelDeclaration() throws -> Expression {
        return try ExpressionParser(ts).expression()
    }

    /*
    private func mergeAST(tlds: [TopLevelDeclaration]) throws -> TopLevelDeclaration {
        // TODO
    }

    private func topLevelDeclaration() throws -> TopLevelDeclaration {
        let sp = StatementParser(ts)
        let b = TopLevelDeclarationBuilder()
        while ts.look().kind != .EndOfFile {
            b.add(try sp.statement())
        }
        return b.build()
    }
    */
}
