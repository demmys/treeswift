enum CharacterClass {
    case EndOfFile, LineFeed, Semicolon
    case LeftParenthesis, RightParenthesis
    case OperatorHead, DotOperatorHead, OperatorFollow
    case Dot
    case Literal
    // Following class would not be put into composers
    case Space
    // Following class would not be a previous character
    case LineCommentHead, BlockCommentHead, BlockCommentTail
}

enum TokenKind {
    case Error(ErrorMessage)
    case Space, LineFeed, Semicolon, EndOfFile
    case LeftParenthesis, RightParenthesis
    case IntegerLiteral(Int)
    case BinaryOperator(String), PrefixOperator(String), PostfixOperator(String)
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
    case .LeftParenthesis:
        switch b {
        case .LeftParenthesis:
            return true
        default:
            return false
        }
    case .RightParenthesis:
        switch b {
        case .RightParenthesis:
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
    case .BinaryOperator:
        switch b {
        case .BinaryOperator:
            return true
        default:
            return false
        }
    case .PrefixOperator:
        switch b {
        case .PrefixOperator:
            return true
        default:
            return false
        }
    case .PostfixOperator:
        switch b {
        case .PostfixOperator:
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
    var kind: TokenKind
    var info: SourceInfo

    var source: String? {
        get { return info.source }
        set(src) { info.source = src }
    }
    var lineNo: Int { get { return info.lineNo } }
    var charNo: Int { get { return info.charNo } }

    init(kind: TokenKind, info: SourceInfo) {
        self.kind = kind
        self.info = info
    }
}

protocol TokenPeeper {
    func look() -> Token
    func look(ahead: Int) -> Token
}

class TokenStream : TokenPeeper {
    private struct Context {
        var cs: CharacterStream
        var source: String? = nil
        var prev: CharacterClass = .LineFeed

        var lineNo: Int { get { return cs.lineNo } }
        var charNo: Int { get { return cs.charNo } }
        var cp: CharacterPeeper { get { return cs } }

        init(cs: CharacterStream) {
            self.cs = cs
        }

        mutating func reset() {
            source = nil
        }

        mutating func consume(consumed: CharacterClass? = nil, n: Int = 1) {
            if let cc = consumed {
                prev = cc
            }
            for var i = 0; i < n; ++i {
                let c = cs.look()!
                if source == nil {
                    source = String(c)
                } else {
                    source!.append(c)
                }
                cs.consume()
            }
        }
    }

    private var queue: [Token]!
    private var index: Int!
    private var ctx: Context!

    init?(_ file: File) {
        if let cs = CharacterStream(file) {
            ctx = Context(cs: cs)
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

    func next(n: Int = 1) {
        index! += n
    }

    private func load(classified: CharacterClass? = nil) -> Token {
        var info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
        func produce(kind: TokenKind) -> Token {
            info.source = ctx.source
            ctx.reset()
            return Token(kind: kind, info: info)
        }

        let head = classified ?? classify(ctx.cp)
        switch head {
        case .EndOfFile:
            return produce(.EndOfFile)
        case .LineFeed:
            if ctx.prev == .LineFeed {
                // remove duplicated line feed
                while true {
                    let cc = classify(ctx.cp)
                    if cc == .LineFeed {
                        ctx.consume()
                    } else {
                        ctx.reset()
                        return load(classified: cc)
                    }
                }
            } else {
                ctx.consume(consumed: head)
                return produce(.LineFeed)
            }
        case .Semicolon:
            ctx.consume(consumed: head)
            return produce(.Semicolon)
        case .LeftParenthesis:
            ctx.consume(consumed: head)
            return produce(.LeftParenthesis)
        case .RightParenthesis:
            ctx.consume(consumed: head)
            return produce(.RightParenthesis)
        case .Space:
            ctx.consume(consumed: head)
            while true {
                let cc = classify(ctx.cp)
                if cc == .Space {
                    ctx.consume()
                } else {
                    ctx.reset()
                    return load(classified: cc)
                }
            }
        // Following class characters are only trashed
        case .LineCommentHead:
            ctx.consume(n: 2)
            while true {
                let cc = classify(ctx.cp)
                switch cc {
                case .LineFeed, .EndOfFile:
                    ctx.reset()
                    return load(classified: cc)
                default:
                    ctx.consume()
                }
            }
        case .BlockCommentHead:
            ctx.consume(n: 2)
            var depth = 1
            while depth > 0 {
                switch classify(ctx.cp) {
                case .BlockCommentHead:
                    ctx.consume(n: 2)
                    ++depth
                case .BlockCommentTail:
                    ctx.consume(n: 2)
                    --depth
                case .EndOfFile:
                    info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
                    return produce(.Error(.UnexpectedEOF))
                default:
                    ctx.consume()
                }
            }
            ctx.reset()
            return load()
        case .BlockCommentTail:
            info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
            ctx.consume(n: 2)
            return produce(.Error(.ReservedToken))
        case .OperatorFollow:
            info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
            ctx.consume()
            return produce(.Error(.InvalidToken))
        default:
            break
        }

        var composers = TokenComposersController(prev: ctx.prev)
        var follow = head
        var endOfToken = false
        do {
            composers.put(follow, c: ctx.cp.look()!)
            ctx.consume(consumed: follow)
            follow = classify(ctx.cp)
            // Check whether the follow is the end of token
            switch follow {
            case .OperatorHead, .DotOperatorHead, .OperatorFollow:
                switch head {
                case .OperatorHead, .DotOperatorHead:
                    break
                default:
                    endOfToken = true
                }
            case .Literal:
                switch head {
                case .Literal:
                    break
                default:
                    endOfToken = true
                }
            default:
                endOfToken = true
            }
        } while !endOfToken
        return produce(composers.fixKind(follow))
    }

    private func classify(cp: CharacterPeeper) -> CharacterClass {
        if let c = cp.look() {
            switch c {
            case "\n":
                return .LineFeed
            case ";":
                return .Semicolon
            case "(":
                return .LeftParenthesis
            case ")":
                return .RightParenthesis
            case " ", "\t", "\0", "\r", "\u{000b}", "\u{000c}":
                return .Space
            case ".":
                if let succ = cp.lookAhead() {
                    if succ == "." {
                        return .DotOperatorHead
                    }
                }
                return .Dot
            case "/":
                if let succ = cp.lookAhead() {
                    switch succ {
                    case "*":
                        return .BlockCommentHead
                    case "/":
                        return .LineCommentHead
                    default:
                        return .OperatorHead
                    }
                }
                return .OperatorHead
            case "*":
                if let succ = cp.lookAhead() {
                    if succ == "/" {
                        return .BlockCommentTail
                    }
                }
                return .OperatorHead
            case "\u{0300}"..."\u{036f}", "\u{1dc0}"..."\u{1dff}",
                 "\u{20d0}"..."\u{20ff}", "\u{fe00}"..."\u{fe0f}",
                 "\u{fe20}"..."\u{fe2f}", "\u{e0100}"..."\u{e01ef}":
                return .OperatorFollow
            case "=", "-", "+", "!", "%", "<", ">", "&", "|", "^", "?", "~",
                 "\u{00a1}"..."\u{00a7}", "\u{00a9}", "\u{00ab}", "\u{00ac}",
                 "\u{00ae}", "\u{00b0}", "\u{00b1}", "\u{00b6}", "\u{00bb}",
                 "\u{00bf}", "\u{00d7}", "\u{00f7}", "\u{2016}", "\u{2017}",
                 "\u{2020}"..."\u{2027}", "\u{2030}"..."\u{203e}",
                 "\u{2041}"..."\u{2053}", "\u{2055}"..."\u{205e}",
                 "\u{2190}"..."\u{23ff}", "\u{2500}"..."\u{2775}",
                 "\u{2794}"..."\u{2bff}", "\u{2e00}"..."\u{2e7f}",
                 "\u{3001}"..."\u{3003}", "\u{3008}"..."\u{3030}":
                return .OperatorHead
            default:
                return .Literal
            }
        } else {
            return .EndOfFile
        }
    }
}
