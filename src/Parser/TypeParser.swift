class TypeParser : GrammarParser {
    private let ap: AttributesParser
    private let gp: GenericsParser

    init(_ ts: TokenStream) {
        ap = AttributesParser(ts)
        gp = GenericsParser(ts)
        super.init(ts)
    }

    func type() throws -> Type {
        switch ts.try(identifier, .LeftBracket, .LeftParenthesis, .Protocol) {
        case let .Identifier(s):
            return try containerType(try identifierType(s))
        case .LeftBracket:
            return try containerType(try collectionType())
        case .LeftParenthesis:
            return try containerType(try tupleType())
        case .Protocol:
            return try containerType(try protocolCompositionType())
        default:
            throw ParserError.Error("Expected type", ts.look().info)
        }
    }

    private func identifierType(s: String) throws -> Type {
        return IdentifierType(try getTypeRef(s), try gp.genericArgumentClause())
    }

    private func collectionType() throws -> Type {
        let t = try type()
        switch ts.try(.RightBracket, .Colon) {
        case .RightBracket:
            return ArrayType(t)
        case .Colon:
            return DictionaryType(t, try type())
        default:
            throw ParserError.Error("Expected ']' for array type or ':' for dictionary type", ts.look().info)
        }
    }

    private func tupleType() throws -> Type {
        let x = TupleType()
        // unit
        if ts.test(.RightParenthesis) {
            return x
        }
        while {
            x.elems.append(try tupleTypeElement())
        } ts.test(.Comma)
        switch ts.try(.VariadicSymbol, .RightParenthesis) {
        case .VariadicSymbol:
            x.variadic = true
            guard ts.test(.RightParenthesis) else {
                throw ParserError.Error("Expected ')' at the end of tuple type", ts.look().info)
            }
            return x
        case .RightParenthesis:
            return x
        default:
            throw ParserError.Error("Expected ')' at the end of tuple type", ts.look().info)
        }
    }

    private func tupleTypeElement() throws -> Type {
        let x = TupleTypeElement()
        switch ts.look().kind {
        case .Atmark:
            x.attrs = ap.attributes()
            if ts.test(.Inout) {
                x.inOut = true
            }
            x.type = try type()
            return x
        case .Inout:
            x.inOut = true
            ts.next()
            if case .Identifier(s) = ts.look().kind {
                return tupleTypeElementBody(x, s)
            }
        case .Identifier(s):
            return tupleTypeElementBody(x, s)
        default:
            x.type = try type()
            return x
        }
    }

    private func tupleTypeElementBody(
        x: TupleTypeElement, _ s: String
    ) -> TupleTypeElement {
        if case .Colon = ts.look(1).kind {
            ts.next(2)
            x.label = s
            x.type = try type()
            return x
        }
        x.type = try type()
        return x
    }

    private func protocolCompositionType() throws -> Type {
        guard ts.test(.PrefixGraterThan) else {
            throw ParserError.Error("Expected following '<' for protocol composition type", ts.look().info)
        }
        let x = ProtocolCompositionType()
        // empty list
        if ts.test(.PostfixLessThan) {
            return x
        }
        repeat {
            x.types.append(try typeIdentifier())
        } while ts.test(.Comma)
        guard ts.test(.PostfixLessThan) else {
            throw ParserError.Error("Expected '>' at the end of protocol composition type", ts.look().info)
        }
        return x
    }

    private func containerType(t: Type) throws -> Type {
        switch ts.try(
            .Throws, .Rethrows, .Arrow, .PostfixQuestion, .PostfixExclamation, .Dot
        ) {
        case .Throws:
            return functionType(t, .Throws)
        case .Rethrows:
            return functionType(t, .Rethrows)
        case .Arrow:
            return functionType(t, .Nothing)
        case .PostfixQuestion:
            return OptionalType(t)
        case .PostfixExclamation:
            return ImplicitlyUnwrappedOptionalType(t)
        case .Dot:
            switch ts.try(.TYPE, .PROTOCOL) {
            case .TYPE:
                return MetaType(t)
            case .PROTOCOL:
                return MetaProtocol(t)
            default:
                throw ParserError.Error("Expected 'Type' or 'Protocol' for metatype type", ts.look().info)
            }
        default:
            return t
        }
    }

    private func functionType(t: Type, _ throwType: ThrowType) throws -> Type {
        return FunctionType(t, .Nothing, try type())
    }
}
