class GenericsParser : GrammarParser {
    func genericArgumentClause() throws -> [TypeRef]? {
        guard ts.test(.PrefixGraterThan) else {
            return nil
        }
        var types: [TypeRef] = []
        repeat {
            types.append(try type())
        } while ts.test(.Comma)
        guard ts.test(.PostfixLessThan) else {
            throw ParserError.Error("Expected '>' at the end of generic argument clause.", ts.look().info)
        }
    }
}
