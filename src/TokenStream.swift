enum TokenKind {
    case Error(ErrorInfo)
    case Space, LineFeed, Semicolon, EndOfFile
    case IntegerLiteral(Int)
    case Operator(String)
}

func ==(a: TokenKind, b: TokenKind) -> Bool {
    switch a {
    case .Error:
        switch b {
        case .Error:
            return true
        default:
            return false
        }
    case .Space:
        switch b {
        case .Space:
            return true
        default:
            return false
        }
    case .LineFeed:
        switch b {
        case .LineFeed:
            return true
        default:
            return false
        }
    case .Semicolon:
        switch b {
        case .Semicolon:
            return true
        default:
            return false
        }
    case .EndOfFile:
        switch b {
        case .EndOfFile:
            return true
        default:
            return false
        }
    case .IntegerLiteral:
        switch b {
        case .IntegerLiteral:
            return true
        default:
            return false
        }
    case .Operator:
        switch b {
        case .Operator:
            return true
        default:
            return false
        }
    }
}

func !=(a: TokenKind, b: TokenKind) -> Bool {
    return !(a == b)
}

struct Token {
    var kind: TokenKind!
    var source: String!
    var lineNo: Int
    var charNo: Int

    init(lineNo: Int, charNo: Int) {
        self.lineNo = lineNo
        self.charNo = charNo
    }

    init(kind: TokenKind, source: String, lineNo: Int, charNo: Int) {
        self.init(lineNo: lineNo, charNo: charNo)
        self.kind = kind
        self.source = source
    }
}

protocol TokenPeeper {
    func look() -> Token
    func look(ahead: Int) -> Token
}

class TokenStream : TokenPeeper {
    private enum State {
        case ParseHead
        case SpaceParse
        case CommentParse(Int)
        case LineCommentParse
        case OperatorParse
        case ComposerParse(TokenComposersController)
    }

    private struct Context {
        var state: State = .ParseHead
        var source: String = ""
        var lineNo: Int = 1
        var charNo: Int = 1
    }

    private let cs: CharacterStream!
    private var ctx = Context()
    private var queue: [Token]!
    private var index: Int!

    init?(_ file: File) {
        cs = CharacterStream(file)
        if cs != nil {
            queue = [load()]
            index = 0
        } else {
            return nil
        }
    }

    func look() -> Token {
        return look(0)
    }

    func look(ahead: Int) -> Token {
        if index + ahead >= queue.count {
            for var i = queue.count - 1; i < index + ahead; ++i {
                queue.append(load())
            }
        }
        return queue[index + ahead]
    }

    func next() {
        ++index!
    }

    private func load() -> Token {
        let returnProcedure = tokenReturnProcedure(ctx.lineNo, charNo: ctx.charNo)
        while true {
            /*
             * Change context, consume character and
             * return token when the analyzation finished
             */
            if let c = cs.look() {
                switch ctx.state {
                case .ParseHead:
                    switch c {
                    case "\n":
                        ++ctx.lineNo
                        ctx.charNo = 1
                        consumeCharacter(c)
                        return returnProcedure(.LineFeed)
                    case ";":
                        ++ctx.charNo
                        consumeCharacter(c)
                        return returnProcedure(.Semicolon)
                    case " ", "\t":
                        ++ctx.charNo
                        fallthrough
                    case "\0", "\r", "\u{000b}", "\u{000c}":
                        // These characters are not counted
                        ctx.state = .SpaceParse
                        consumeCharacter(c)
                    case "/":
                        if let succ = cs.lookAhead() {
                            switch succ {
                            case "*":
                                ctx.charNo += 2
                                ctx.state = .CommentParse(0)
                                consumeCharacter(c)
                                consumeCharacter(succ)
                                continue
                            case "/":
                                ctx.charNo += 2
                                ctx.state = .LineCommentParse
                                consumeCharacter(c)
                                consumeCharacter(succ)
                                continue
                            default:
                                break
                            }
                        }
                        fallthrough
                    case "*":
                        if let succ = cs.lookAhead() {
                            if succ == "/" {
                                consumeCharacter(c)
                                consumeCharacter(succ)
                                let r = "Operator */ is reserved for comment syntax"
                                let ei = ErrorInfo(reason: r)
                                return returnProcedure(.Error(ei))
                            }
                        }
                        fallthrough
                    case "=", "-", "+", "!", "%", "<",
                         ">", "&", "|", "^", "?", "~":
                        ++ctx.charNo
                        ctx.state = .OperatorParse
                        consumeCharacter(c)
                    default:
                        ++ctx.charNo
                        var composers = TokenComposersController()
                        composers.put(c)
                        ctx.state = .ComposerParse(composers)
                        consumeCharacter(c)
                    }
                case .SpaceParse:
                    switch c {
                    case " ", "\t":
                        ++ctx.charNo
                        fallthrough
                    case "\0", "\r", "\u{000b}", "\u{000c}":
                        // These characters are not counted
                        consumeCharacter(c)
                    default:
                        // Do not consume character
                        return returnProcedure(.Space)
                    }
                case let .CommentParse(n):
                    switch c {
                    case "*":
                        if let succ = cs.lookAhead() {
                            if succ == "/" {
                                ctx.charNo += 2
                                consumeCharacter(c)
                                consumeCharacter(succ)
                                if n == 0 {
                                    return returnProcedure(.Space)
                                } else {
                                    ctx.state = .CommentParse(n - 1)
                                }
                            }
                        } else {
                            consumeCharacter(c)
                            return unexpectedEOFProcedure(returnProcedure,
                                                          parsing: "comment")
                        }
                    case "/":
                        if let succ = cs.lookAhead() {
                            if succ == "*" {
                                ctx.charNo += 2
                                ctx.state = .CommentParse(n + 1)
                                consumeCharacter(c)
                                consumeCharacter(succ)
                            }
                        } else {
                            consumeCharacter(c)
                            return unexpectedEOFProcedure(returnProcedure,
                                                          parsing: "comment")
                        }
                    default:
                        ++ctx.charNo
                        consumeCharacter(c)
                    }
                case .LineCommentParse:
                    switch c {
                    case "\n":
                        // Do not consume character
                        return returnProcedure(.Space)
                    default:
                        ++ctx.charNo
                        consumeCharacter(c)
                    }
                case .OperatorParse:
                    switch c {
                    case "/", "=", "-", "+", "!", "*", "%",
                         "<", ">", "&", "|", "^", "?", "~":
                        ++ctx.charNo
                        consumeCharacter(c)
                    default:
                        // Do not consume character
                        return returnProcedure(.Operator(ctx.source))
                    }
                case let .ComposerParse(composers):
                    switch c {
                    case "\n", " ", "\t", ";",
                         "\0", "\r", "\u{000b}", "\u{000c}",
                         "/", "=", "-", "+", "!", "*", "%",
                         "<", ">", "&", "|", "^", "?", "~":
                        // Do not consume character
                        return returnProcedure(composers.fixKind())
                    default:
                        ++ctx.charNo
                        composers.put(c)
                        consumeCharacter(c)
                    }
                }
            } else {
                switch ctx.state {
                case .ParseHead:
                    return returnProcedure(.EndOfFile)
                case .SpaceParse:
                    return returnProcedure(.Space)
                case .CommentParse:
                    return unexpectedEOFProcedure(returnProcedure, parsing: "comment")
                case .LineCommentParse:
                    return returnProcedure(.Space)
                case .OperatorParse:
                    return returnProcedure(.Operator(ctx.source))
                case let .ComposerParse(composers):
                    let kind = composers.fixKind()
                    switch kind {
                    case let .Error(i):
                        return unexpectedEOFProcedure(returnProcedure)
                    default:
                        return returnProcedure(kind)
                    }
                }
            }
        }
    }

    /*
     * Helper methods
     */
    private func consumeCharacter(c: Character) {
        ctx.source.append(c)
        cs.next()
    }

    private func tokenReturnProcedure(lineNo: Int, charNo: Int)
        -> TokenKind -> Token {
        return { (kind: TokenKind) -> Token in
            var token = Token(kind: kind, source: self.ctx.source,
                              lineNo: lineNo, charNo: charNo)
            self.ctx.state = .ParseHead
            self.ctx.source = ""
            return token
        }
    }

    private func unexpectedEOFProcedure(returnProcedure: TokenKind -> Token,
                                        parsing: String? = nil) -> Token {
        var r = "Unexpected end of file"
        if let p = parsing {
            r = "\(r) while parsing \(p)"
        }
        let ei = ErrorInfo(reason: r)
        return returnProcedure(.Error(ei))
    }
}
