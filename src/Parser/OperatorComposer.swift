class OperatorComposer : TokenComposer {
    private enum State {
        case Head
        case ReservedOperator(CharacterClass)
        case DotOperatorHead
        case OperatorCharacter, DotOperatorCharacter
    }

    private var state = State.Head
    private var prev: CharacterClass
    private var value: String?

    init(prev: CharacterClass){
        self.prev = prev
    }

    func put(cc: CharacterClass, _ c: Character) -> Bool {
        switch state {
        case .Head:
            switch cc {
            case .OperatorHead:
                value = String(c)
                state = .OperatorCharacter
                return true
            case .DotOperatorHead:
                value = String(c)
                state = .DotOperatorHead
                return true
            case .LessThan, .GraterThan, .Ampersand, .Question, .Exclamation:
                value = String(c)
                state = .ReservedOperator(cc)
                return true
            default:
                value = nil
                return false
            }
        case .DotOperatorHead:
            switch cc {
            case .DotOperatorHead, .Dot:
                value!.append(c)
                state = .DotOperatorCharacter
                return true
            default:
                value = nil
                return false
            }
        case .OperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow, .LessThan, .GraterThan,
                 .Ampersand, .Question, .Exclamation, .Equal, .Arrow, .Minus,
                 .LineCommentHead, .BlockCommentHead, .BlockCommentTail:
                value!.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .DotOperatorCharacter:
            switch cc {
            case .OperatorHead, .OperatorFollow, .LessThan, .GraterThan,
                 .Ampersand, .Question, .Exclamation, .Equal, .Arrow, .Minus,
                 .LineCommentHead, .BlockCommentHead, .BlockCommentTail,
                 .DotOperatorHead, .Dot:
                value!.append(c)
                return true
            default:
                value = nil
                return false
            }
        case .ReservedOperator:
            value = nil
            return false
        }
    }

    func compose(follow: CharacterClass) -> TokenKind? {
        if let v = value {
            let kind = createKind(prev: self.prev, value: v, follow: follow)
            switch state {
            case .OperatorCharacter, .DotOperatorCharacter:
                return kind
            case let .ReservedOperator(cc):
                switch cc {
                case .LessThan:
                    switch kind {
                    case .PrefixOperator:
                        return .PrefixLessThan
                    default:
                        return kind
                    }
                case .GraterThan:
                    switch kind {
                    case .PostfixOperator:
                        return .PostfixGraterThan
                    default:
                        return kind
                    }
                case .Ampersand:
                    switch kind {
                    case .PrefixOperator:
                        return .PrefixAmpersand
                    default:
                        return kind
                    }
                case .Question:
                    switch kind {
                    case .PrefixOperator:
                        return .PrefixQuestion
                    case .BinaryOperator:
                        return .BinaryQuestion
                    case .PostfixOperator:
                        return .PostfixQuestion
                    default:
                        assert(false,
                               "[System Error] Unimplemented operator type found.")
                    }
                case .Exclamation:
                    switch kind {
                    case .PostfixOperator:
                        return .PostfixExclamation
                    default:
                        return kind
                    }
                default:
                    assert(false,
                           "[System Error] Unimplemented reserved operator found.")
                }
            default:
                break
            }
        }
        return nil
    }

    private func createKind(prev prev: CharacterClass, value: String,
                            follow: CharacterClass) -> TokenKind {
        let headSeparated = isSeparator(prev, isPrev: true)
        let tailSeparated = isSeparator(follow, isPrev: false)
        if headSeparated {
            if tailSeparated {
                return .BinaryOperator(value)
            }
            return .PrefixOperator(value)
        } else {
            if tailSeparated {
                return .PostfixOperator(value)
            }
            return .BinaryOperator(value)
        }
    }

    private func isSeparator(cc: CharacterClass, isPrev: Bool) -> Bool {
        switch cc {
        case .EndOfFile, .LineFeed, .Semicolon, .Space:
            return true
        case .BlockCommentTail, .LeftParenthesis, .LeftBrace, .LeftBracket:
            return isPrev
        case .BlockCommentHead, .RightParenthesis, .RightBrace, .RightBracket:
            return !isPrev
        default:
            return false
        }
    }
}
