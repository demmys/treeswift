class GenericsParser : GrammarParser {
    var tp: TypeParser!

    func setParser(typeParser tp: TypeParser) {
        self.tp = tp
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
