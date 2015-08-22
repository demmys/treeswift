class AttributesParser : GrammarParser {
    func lookAfterAttributes(startIndex: Int = 0) throws -> ([Attribute], Int) {
        var i = startIndex
        var attrs: [Attribute] = []
        while case .Atmark = ts.look(i++).kind {
            attrs.append(try lookAttribute(i))
        }
        return (attrs, i)
    }

    func lookAttribute(startIndex: Int = 0) throws -> Attribute {
        let token = ts.look(startIndex)
        if case let .Identifier(s) = token.kind {
            return Attribute(s)
        } else {
            throw ParserError.Error("Expected identifier for attribute", token.info)
        }
    }

    func attributes() throws -> [Attribute] {
        var attrs: [Attribute] = []
        while ts.test([.Atmark]) {
            attrs.append(try attribute())
        }
        return attrs
    }

    private func attribute() throws -> Attribute {
        if case let .Identifier(s) = ts.match([identifier]) {
            return Attribute(s)
        } else {
            throw ParserError.Error("Expected identifier for attribute", ts.look().info)
        }
    }

    func declarationModifiers() throws -> [Modifier] {
        var ms: [Modifier] = []
        while let m = try declarationModifier() {
            ms.append(m)
        }
        return ms
    }

    private func declarationModifier() throws -> Modifier? {
        switch ts.match([modifier]) {
        case let .Modifier(k):
            switch k {
                case .Convenience:
                    return .Convenience
                case .Dynamic:
                    return .Dynamic
                case .Final:
                    return .Final
                case .Lazy:
                    return .Lazy
                case .Mutating:
                    return .Mutating
                case .Nonmutating:
                    return .Nonmutating
                case .Optional:
                    return .Optional
                case .Override:
                    return .Override
                case .Required:
                    return .Required
                case .Static:
                    return .Static
                case .Weak:
                    return .Weak
                case .Unowned:
                    if case .LeftParenthesis = ts.look().kind {
                        switch ts.match([.Safe, .Unsafe], ahead: 1) {
                        case .Safe:
                            guard ts.test([.RightParenthesis]) else {
                                throw ParserError.Error("Expected ')' after 'safe' for unowned modifier", ts.look().info)
                            }
                            return .UnownedSafe
                        case .Unsafe:
                            guard ts.test([.RightParenthesis]) else {
                                throw ParserError.Error("Expected ')' after 'unsafe' for unowned modifier", ts.look().info)
                            }
                            return .UnownedUnsafe
                        default:
                            throw ParserError.Error("Expected 'safe' or 'unsafe' after '('", ts.look().info)
                        }
                    }
                    return .Unowned
                case .Internal, .Private, .Public:
                    return try accessLevelModifier(k)
            }
        case .Class:
            if case .Identifier = ts.look().kind {
                return nil
            }
            ts.next()
            return .Class
        case .Infix:
            if case .Operator = ts.look().kind {
                return nil
            }
            ts.next()
            return .Infix
        case .Prefix:
            if case .Operator = ts.look().kind {
                return nil
            }
            ts.next()
            return .Prefix
        case .Postfix:
            if case .Operator = ts.look().kind {
                return nil
            }
            ts.next()
            return .Postfix
        default:
            return nil
        }
    }

    func accessLevelModifiers() throws -> [Modifier] {
        var ms: [Modifier] = []
        while let m = try accessLevelModifier() {
            ms.append(m)
        }
        return ms
    }

    private func accessLevelModifier(looked: ModifierKind? = nil) throws -> Modifier? {
        var target: ModifierKind!
        if looked == nil {
            switch ts.look().kind {
            case let .Modifier(k):
                switch k {
                case .Internal, .Private, .Public:
                    target = k
                default:
                    return nil
                }
            default:
                return nil
            }
        } else {
            target = looked
        }
        switch target! {
        case .Internal:
            if case .LeftParenthesis = ts.look().kind {
                guard ts.test([.Set], ahead: 1) else {
                    throw ParserError.Error("Expected 'set' after '('", ts.look().info)
                }
                guard ts.test([.RightParenthesis]) else {
                    throw ParserError.Error("Expected ')' after 'set' for access modifier", ts.look().info)
                }
                return .InternalSet
            }
            return .Internal
        case .Private:
            if case .LeftParenthesis = ts.look().kind {
                guard ts.test([.Set], ahead: 1) else {
                    throw ParserError.Error("Expected 'set' after '('", ts.look().info)
                }
                guard ts.test([.RightParenthesis]) else {
                    throw ParserError.Error("Expected ')' after 'set' for access modifier", ts.look().info)
                }
                return .PrivateSet
            }
            return .Private
        case .Public:
            if case .LeftParenthesis = ts.look().kind {
                guard ts.test([.Set], ahead: 1) else {
                    throw ParserError.Error("Expected 'set' after '('", ts.look().info)
                }
                guard ts.test([.RightParenthesis]) else {
                    throw ParserError.Error("Expected ')' after 'set' for access modifier", ts.look().info)
                }
                return .PublicSet
            }
            return .Public
        default:
            break
        }
        return nil
    }
}
