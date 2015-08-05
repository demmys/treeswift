import Util

enum ParserError : ErrorType {
    case FileNotFound(String)
    case FileCanNotRead(String)
    case Error(String, SourceInfo)
}

public enum ParseResult {
    case Succeeded([String:[Procedure]])
    case Failed([Error])
}

public class Parser {
    private let fileNames: [String]
    private var ts: TokenStream!

    public init(_ fileNames: [String]) {
        self.fileNames = fileNames
    }

    public func parse() -> ParseResult {
        var result: [String:[Procedure]] = [:]
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

    private func topLevelDeclaration() throws -> [Procedure] {
        let ap = AttributesParser(ts)
        let gp = GenericsParser(ts)
        let tp = TypeParser(ts)
        let ep = ExpressionParser(ts)
        let dp = DeclarationParser(ts)
        let pp = PatternParser(ts)
        let parser = ProcedureParser(ts)
        gp.setParser(typeParser: tp)
        tp.setParser(attributesParser: ap, genericsParser: gp)
        ep.setParser(
            typeParser: tp, genericsParser: gp, procedureParser: parser,
            expressionParser: ep, declarationParser: dp
        )
        dp.setParser(
            patternParser: pp, expressionParser: ep, typeParser: tp,
            attributesParser: ap
        )
        pp.setParser(typeParser: tp, expressionParser: ep)
        parser.setParser(
            declarationParser: dp, patternParser: pp, expressionParser: ep
        )
        return try parser.procedures()
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
