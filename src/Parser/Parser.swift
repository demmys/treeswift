import Util
import AST

public class Parser {
    private let fileNames: [String]
    private var ts: TokenStream!

    public init(_ fileNames: [String]) {
        self.fileNames = fileNames
    }

    public func parse() throws -> [String:TopLevelDeclaration] {
        var result: [String:TopLevelDeclaration] = [:]
        for fileName in fileNames {
            do {
                ts = try createStream(fileName)
                result[fileName] = try topLevelDeclaration()
                ErrorReporter.bundle(fileName)
            } catch let e {
                ErrorReporter.bundle(fileName)
                throw e
            }
        }
        if ErrorReporter.hasErrors() {
            throw ErrorReport.Found
        }
        return result
    }

    private func createStream(fileName: String) throws -> TokenStream {
        guard let f = File(name: fileName, mode: "r") else {
            throw ErrorReporter.fatal(.FileNotFound(fileName), nil)
        }
        guard let ts = TokenStream(file: f) else {
            throw ErrorReporter.fatal(.FileCanNotRead(fileName), nil)
        }
        return ts
    }

    private func topLevelDeclaration() throws -> TopLevelDeclaration {
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
            procedureParser: parser, patternParser: pp, expressionParser: ep,
            typeParser: tp, attributesParser: ap, genericsParser: gp
        )
        pp.setParser(typeParser: tp, expressionParser: ep)
        parser.setParser(
            declarationParser: dp, patternParser: pp,expressionParser: ep,
            attributesParser: ap
        )
        ScopeManager.enterScope(.File)
        return TopLevelDeclaration(
            procedures: try parser.procedures(),
            fileScope: try ScopeManager.leaveScope(.File, nil)
        )
    }
}

public class TopLevelDeclaration : ScopeTrackable, CustomStringConvertible {
    public let procedures: [Procedure]
    public let fileScope: Scope

    public init(procedures: [Procedure], fileScope: Scope) {
        self.procedures = procedures
        self.fileScope = fileScope
    }

    public var scope: Scope { return fileScope }
    public var description: String {
        return "(TopLevelDeclaration \(procedures))"
    }
}
