class GenericsParser : GrammarParser {
    private var tp: TypeParser!

    func setParser(typeParser tp: TypeParser) {
        self.tp = tp
    }

    func requirementClause() throws -> [Requirement] {
        guard ts.test([.Where]) else {
            return []
        }
        var rs: [Requirement] = []
        repeat {
            rs.append(try requirement())
        } while ts.test([.Comma])
        return rs
    }

    func requirement() throws -> Requirement {
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ParserError.Error("Expected identifier at the beggining of requirement", ts.look().info)
        }
        let i = try tp.identifierType(s)
        switch ts.match([.Colon, identifier]) {
        case .Colon:
            if case let .Identifier(s) = ts.match([identifier]) {
                return .Conformance(i, try tp.identifierType(s))
            } else {
                return .Conformance(i, try tp.protocolCompositionType())
            }
        case let .BinaryOperator(o):
            if o == "==" {
                return .SameType(i, try tp.type())
            } else {
                throw ParserError.Error("Expected '==' for the same type requirement", ts.look().info)
            }
        default:
            throw ParserError.Error("Expected ':' for the conformance requirement or '==' for the same type requirement", ts.look().info)
        }
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
