class AttributesParser : GrammarParser {
    func attributes() throws -> [Attribute] {
        var attrs: [Attribute] = []
        while ts.test(.Atmark) {
            attrs.append(try attribute())
        }
        return attrs
    }

    private func attribute() throws -> Attribute {
        if case let .Identifier(.Identifier(s)) = ts.test(identifier) {
            return Attribute(s)
        } else {
            throw ParserError.Error("Expected identifier for attribute", ts.look().info)
        }
    }
}
