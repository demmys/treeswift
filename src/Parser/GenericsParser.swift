class GenericsParser : GrammarParser {
    func genericArgumentClause() throws -> [Type]? {
        guard ts.test(.PrefixGraterThan) else {
            return nil
        }
        var types: [Type] = []
        repeat {
            types.append(try type())
        } while ts.test(.Comma)
        guard ts.test(.PostfixLessThan) else {
            throw ParserError.Error("Expected '>' at the end of generic argument clause.", ts.look().info)
        }
    }
}
