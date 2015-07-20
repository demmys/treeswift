class GenericsParser : GrammarParser {
    private let tp: TypeParser

    override init(_ ts: TokenStream) {
        tp = TypeParser(ts)
        super.init(ts)
    }

    func genericArgumentClause() throws -> [Type]? {
        guard ts.test([.PrefixLessThan]) else {
            return nil
        }
        var types: [Type] = []
        repeat {
            types.append(try tp.type())
        } while ts.test([.Comma])
        guard ts.test([.PostfixGraterThan]) else {
            throw ParserError.Error("Expected '>' at the end of generic argument clause.", ts.look().info)
        }
        return types
    }
}
