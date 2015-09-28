class GenericsParser : GrammarParser {
    private var tp: TypeParser!

    func setParser(typeParser tp: TypeParser) {
        self.tp = tp
    }

    func genericParameterClause() throws -> GenericParameterClause? {
        guard ts.test([.PrefixLessThan]) else {
            return nil
        }
        let x = GenericParameterClause()
        repeat {
            x.params.append(try genericParameter())
        } while ts.test([.Comma])
        x.reqs = try requirementClause()
        if !ts.test([.PostfixGraterThan]) {
            try ts.error(.ExpectedGraterThanAfterGenericParameter)
        }
        return x
    }

    func genericParameter() throws -> GenericParameter {
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedGenericParameterName)
        }
        let r = try createTypeRef(s)
        if ts.test([.Colon]) {
            if case let .Identifier(s) = ts.match([identifier]) {
                return .Conformance(r, try tp.identifierType(s))
            } else {
                return .ProtocolConformance(r, try tp.protocolCompositionType())
            }
        }
        return .Identifier(r)
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
            throw ts.fatal(.ExpectedIdentifierForRequirement)
        }
        let i = try tp.identifierType(s)
        switch ts.match([.Colon, binaryOperator]) {
        case .Colon:
            if case let .Identifier(s) = ts.match([identifier]) {
                return .Conformance(i, try tp.identifierType(s))
            } else {
                return .ProtocolConformance(i, try tp.protocolCompositionType())
            }
        case let .BinaryOperator(o):
            if o == "==" {
                return .SameType(i, try tp.type())
            } else {
                throw ts.fatal(.ExpectedDoubleEqual)
            }
        default:
            throw ts.fatal(.ExpectedRequirementSymbol)
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
        if !ts.test([.PostfixGraterThan]) {
            try ts.error(.ExpectedGraterThanAfterGenericParameter)
        }
        return types
    }
}
