import Util
import AST

public struct Token : SourceTrackable, CustomStringConvertible {
    public var kind: TokenKind
    private let info: SourceInfo

    public var sourceInfo: SourceInfo {
        return info
    }

    private init(kind: TokenKind, info: SourceInfo) {
        self.kind = kind
        self.info = info
    }

    public var description: String {
        return "\(kind)"
    }
}

class TokenStream {
    private struct Context {
        // set `CharacterClass.LineFeed` to `prev`
        // in order to remove line feed in the head of the file
        var prev: CharacterClass = .LineFeed
        var exprev: CharacterClass = .LineFeed

        let _cs: CharacterStream
        var cp: CharacterPeeper {
            return _cs
        }

        init?(file: File) {
            guard let cs = CharacterStream(file) else {
                return nil
            }
            _cs = cs
        }

        mutating func consume(consumed: CharacterClass? = nil, n: Int = 1) {
            if let cc = consumed {
                exprev = prev
                prev = cc
            }
            for var i = 0; i < n; ++i {
                _cs.consume()
            }
        }

        func generateSourceInfo() -> SourceInfo {
            return SourceInfo(
                seekNo: _cs.seekNo, lineNo: _cs.lineNo, charNo: _cs.charNo
            )
        }
    }

    private var queue: [Token]!
    private var ctx: Context!
    private var classifier: CharacterClassifier!

    init?(file: File) {
        guard let ctx = Context(file: file) else {
            return nil
        }
        self.ctx = ctx
        classifier = CharacterClassifier(cp: ctx.cp)
        queue = [load()]
    }

    func fatal(message: ErrorMessage, token: Token? = nil) -> ErrorReport {
        return ErrorReporter.instance.fatal(message, token ?? look())
    }
    func error(message: ErrorMessage, token: Token? = nil) throws {
        try ErrorReporter.instance.error(message, token ?? look())
    }
    func warning(message: ErrorMessage, token: Token? = nil) {
        ErrorReporter.instance.warning(message, token ?? look())
    }

    func look(var ahead: Int = 0, skipLineFeed: Bool = true) -> Token {
        if ahead >= queue.count {
            for var i = queue.count - 1; i < ahead; ++i {
                queue.append(load())
            }
        }
        if skipLineFeed {
            for var i = 0; i < ahead; ++i {
                if queue[i].kind == .LineFeed {
                    ++ahead
                    if ahead >= queue.count {
                        queue.append(load())
                    }
                }
            }
        }
        // print("\tlooking queue: \(queue) (currently ahead: \(ahead))") // DEBUG
        let top = queue[ahead]
        if skipLineFeed && top.kind == .LineFeed {
            return look(ahead + 1, skipLineFeed: false)
        }
        return top
    }

    func next(n: Int = 1, skipLineFeed: Bool = true) {
        guard n > 0 else {
            return
        }
        let first = queue.removeFirst()
        if skipLineFeed && first.kind == .LineFeed {
            next(n, skipLineFeed: skipLineFeed)
        } else {
            next(n - 1, skipLineFeed: skipLineFeed)
        }
    }

    func test(kinds: [TokenKind], ahead: Int = 0) -> Bool {
        return examine(kinds, ahead: ahead).0
    }

    func match(kinds: [TokenKind], ahead: Int = 0) -> TokenKind {
        return examine(kinds, ahead: ahead).1
    }

    private func examine(kinds: [TokenKind], ahead: Int) -> (Bool, TokenKind) {
        let skipLineFeed = !kinds.contains(.LineFeed)
        let t = look(ahead, skipLineFeed: skipLineFeed)
        for k in kinds {
            if t.kind == k {
                next(ahead + 1, skipLineFeed: skipLineFeed)
                return (true, t.kind)
            }
        }
        return (false, t.kind)
    }

    private func load(classified: CharacterClass? = nil) -> Token {
        var info = ctx.generateSourceInfo()
        let produce = { Token(kind: $0, info: info) }
        let refreshAndProduce = { (kind: TokenKind) -> Token in
            info = self.ctx.generateSourceInfo()
            return produce(kind)
        }
        let head = classified ?? classifier.classify()
        switch head {
        case .CarriageReturn:
            // ignore
            ctx.consume()
            return load()
        case .EndOfFile:
            return produce(.EndOfFile)
        case .LineFeed:
            switch ctx.prev {
            case .Space:
                // ignore line which is composed of the only spaces or block comments
                if ctx.exprev == .LineFeed {
                    fallthrough
                }
            case .LineFeed:
                // remove duplicated line feed (includes current one)
                ctx.consume()
                while true {
                    let cc = classifier.classify()
                    if cc == .LineFeed {
                        ctx.consume()
                    } else {
                        return load(cc)
                    }
                }
            default:
                break
            }
            ctx.consume(head)
            return produce(.LineFeed)
        case .Space:
            if ctx.prev == .Space {
                // remove duplicated space (includes current one)
                ctx.consume()
                while true {
                    let cc = classifier.classify()
                    if cc == .Space {
                        ctx.consume()
                    } else {
                        return load(cc)
                    }
                }
            } else {
                ctx.consume(head)
                return load()
            }
        case .Arrow:
            ctx.consume(head, n: 2)
            return produce(.Arrow)
        case .Equal:
            ctx.consume(head)
            return produce(.AssignmentOperator)
        case .Atmark:
            ctx.consume(head)
            return produce(.Atmark)
        case .Colon:
            ctx.consume(head)
            return produce(.Colon)
        case .Comma:
            ctx.consume(head)
            return produce(.Comma)
        case .Dot:
            ctx.consume(head)
            return produce(.Dot)
        case .Semicolon:
            ctx.consume(head)
            return produce(.Semicolon)
        case .Underscore:
            ctx.consume(head)
            return produce(.Underscore)
        case .LeftParenthesis:
            ctx.consume(head)
            return produce(.LeftParenthesis)
        case .RightParenthesis:
            ctx.consume(head)
            return produce(.RightParenthesis)
        case .LeftBrace:
            ctx.consume(head)
            return produce(.LeftBrace)
        case .RightBrace:
            ctx.consume(head)
            return produce(.RightBrace)
        case .LeftBracket:
            ctx.consume(head)
            return produce(.LeftBracket)
        case .RightBracket:
            ctx.consume(head)
            return produce(.RightBracket)
        case .LineCommentHead:
            ctx.consume(n: 2)
            while true {
                let cc = classifier.classify()
                switch cc {
                case .LineFeed, .EndOfFile:
                    // a comment produces nothing
                    // duplicative line feeds will be ignored
                    // in the lexical analyzation of line feed
                    return load(cc)
                default:
                    // ignore comment characters
                    ctx.consume()
                }
            }
        case .BlockCommentHead:
            ctx.consume(n: 2)
            // accepts nested comment
            var depth = 1
            while depth > 0 {
                switch classifier.classify() {
                case .BlockCommentHead:
                    ctx.consume(n: 2)
                    ++depth
                case .BlockCommentTail:
                    if ctx.prev != .Space {
                        // consume like a scape
                        ctx.consume(.Space, n: 2)
                    } else {
                        // avoid duplicative space consumption
                        ctx.consume(n: 2)
                    }
                    --depth
                case .EndOfFile:
                    return refreshAndProduce(.Error(.UnexpectedEOF))
                default:
                    // ignore comment characters
                    ctx.consume()
                }
            }
            // a comment produces nothing
            return load()
        case .BlockCommentTail:
            ctx.consume(n: 2)
            return refreshAndProduce(.Error(.ReservedToken))
        case .OperatorFollow, .IdentifierFollow, .BackSlash, .Others:
            ctx.consume()
            return refreshAndProduce(.Error(.InvalidToken))
        case .LessThan, .GraterThan, .Ampersand, .Question, .Exclamation:
            return produce(
                composerParse(head, composer: OperatorComposer(prev: ctx.prev))
            )
        case .OperatorHead, .DotOperatorHead:
            return produce(
                composerParse(head, composer: OperatorComposer(prev: ctx.prev))
            )
        case .Dollar:
            return produce(
                composerParse(head, composer: IdentifierComposer())
            )
        case .BackQuote:
            return produce(
                composerParse(head, composer: IdentifierComposer())
            )
        case .Minus:
            switch ctx.prev {
            case .LineFeed, .Semicolon, .Space,
                 .BlockCommentTail, .LeftParenthesis, .LeftBrace, .LeftBracket:
                return produce(
                    composerParse(head, composer: NumericLiteralComposer())
                )
            default:
                return produce(
                    composerParse(head, composer: OperatorComposer(prev: ctx.prev))
                )
            }
        case .Digit:
            return produce(
                composerParse(head, composer: NumericLiteralComposer())
            )
        case .DoubleQuote:
            return produce(
                composerParse(head, composer: StringLiteralComposer())
            )
        case .IdentifierHead:
            let composer = IdentifierComposer()
            var reservedWords: [WordLiteralComposer]?
            switch ctx.cp.look()! {
            case "a":
                reservedWords = [
                    WordLiteralComposer("as", .As),
                    WordLiteralComposer("associativity", .Associativity)
                ]
            case "b":
                reservedWords = [WordLiteralComposer("break", .Break)]
            case "c":
                reservedWords = [
                    WordLiteralComposer("catch", .Catch),
                    WordLiteralComposer("case", .Case),
                    WordLiteralComposer("class", .Class),
                    WordLiteralComposer("continue", .Continue),
                    WordLiteralComposer("convenience", .Modifier(.Convenience))
                ]
            case "d":
                reservedWords = [
                    WordLiteralComposer("default", .Default),
                    WordLiteralComposer("defer", .Defer),
                    WordLiteralComposer("deinit", .Deinit),
                    WordLiteralComposer("didSet", .DidSet),
                    WordLiteralComposer("do", .Do),
                    WordLiteralComposer("dynamic", .Modifier(.Dynamic)),
                    WordLiteralComposer("dynamicType", .DynamicType)
                ]
            case "e":
                reservedWords = [
                    WordLiteralComposer("enum", .Enum),
                    WordLiteralComposer("extension", .Extension),
                    WordLiteralComposer("else", .Else)
                ]
            case "f":
                reservedWords = [
                    WordLiteralComposer("fallthrough", .Fallthrough),
                    WordLiteralComposer("false", .BooleanLiteral(false)),
                    WordLiteralComposer("final", .Modifier(.Final)),
                    WordLiteralComposer("for", .For),
                    WordLiteralComposer("func", .Func)
                ]
            case "g":
                reservedWords = [
                    WordLiteralComposer("get", .Get),
                    WordLiteralComposer("guard", .Guard)
                ]
            case "i":
                reservedWords = [
                    WordLiteralComposer("if", .If),
                    WordLiteralComposer("import", .Import),
                    WordLiteralComposer("in", .In),
                    WordLiteralComposer("indirect", .Indirect),
                    WordLiteralComposer("infix", .Infix),
                    WordLiteralComposer("init", .Init),
                    WordLiteralComposer("inout", .InOut),
                    WordLiteralComposer("internal", .Modifier(.Internal)),
                    WordLiteralComposer("is", .Is)
                ]
            case "l":
                reservedWords = [
                    WordLiteralComposer("lazy", .Modifier(.Lazy)),
                    WordLiteralComposer("let", .Let),
                    WordLiteralComposer("left", .Left)
                ]
            case "m":
                reservedWords = [
                    WordLiteralComposer("mutating", .Modifier(.Mutating))
                ]
            case "n":
                reservedWords = [
                    WordLiteralComposer("nil", .Nil),
                    WordLiteralComposer("none", .None),
                    WordLiteralComposer("nonmutating", .Modifier(.Nonmutating))
                ]
            case "o":
                reservedWords = [
                    WordLiteralComposer("operator", .Operator),
                    WordLiteralComposer("optional", .Modifier(.Optional)),
                    WordLiteralComposer("override", .Modifier(.Override))
                ]
            case "p":
                reservedWords = [
                    WordLiteralComposer("postfix", .Postfix),
                    WordLiteralComposer("prefix", .Prefix),
                    WordLiteralComposer("private", .Modifier(.Private)),
                    WordLiteralComposer("protocol", .Protocol),
                    WordLiteralComposer("precedence", .Precedence),
                    WordLiteralComposer("public", .Modifier(.Public))
                ]
            case "r":
                reservedWords = [
                    WordLiteralComposer("repeat", .Repeat),
                    WordLiteralComposer("required", .Modifier(.Required)),
                    WordLiteralComposer("rethrows", .Rethrows),
                    WordLiteralComposer("return", .Return),
                    WordLiteralComposer("right", .Right)
                ]
            case "s":
                reservedWords = [
                    WordLiteralComposer("safe", .Safe),
                    WordLiteralComposer("self", .`Self`),
                    WordLiteralComposer("set", .Set),
                    WordLiteralComposer("static", .Modifier(.Static)),
                    WordLiteralComposer("struct", .Struct),
                    WordLiteralComposer("subscript", .Subscript),
                    WordLiteralComposer("super", .Super),
                    WordLiteralComposer("switch", .Switch)
                ]
            case "t":
                reservedWords = [
                    WordLiteralComposer("throw", .Throw),
                    WordLiteralComposer("throws", .Throws),
                    WordLiteralComposer("try", .Try),
                    WordLiteralComposer("true", .BooleanLiteral(true)),
                    WordLiteralComposer("typealias", .Typealias)
                ]
            case "u":
                reservedWords = [
                    WordLiteralComposer("unowned", .Modifier(.Unowned)),
                    WordLiteralComposer("unsafe", .Unsafe),
                ]
            case "v":
                reservedWords = [WordLiteralComposer("var", .Var)]
            case "w":
                reservedWords = [
                    WordLiteralComposer("weak", .Modifier(.Weak)),
                    WordLiteralComposer("where", .Where),
                    WordLiteralComposer("while", .While),
                    WordLiteralComposer("willSet", .WillSet)
                ]
            case "T":
                reservedWords = [WordLiteralComposer("Type", .TYPE)]
            case "P":
                reservedWords = [WordLiteralComposer("Protocol", .Protocol)]
            case "_":
                reservedWords = [
                    WordLiteralComposer("__COLUMN__", .COLUMN),
                    WordLiteralComposer("__FILE__", .FILE),
                    WordLiteralComposer("__FUNCTION__", .FUNCTION),
                    WordLiteralComposer("__LINE__", .LINE)
                ]
            default:
                break
            }
            var follow = head
            repeat {
                composer.put(follow, ctx.cp.look()!)
                reservedWords = reservedWords?.filter({
                    $0.put(follow, self.ctx.cp.look()!)
                })
                ctx.consume(follow)
                follow = classifier.classify()
            } while !composer.isEndOfToken(follow)

            if let kinds = reservedWords?.map({
                $0.compose(follow)
            }).filter({ $0 != nil }) {
                if kinds.count > 0 {
                    return produce(kinds[0]!)
                }
            }
            if let kind = composer.compose(follow) {
                return produce(kind)
            } else {
                return produce(.Error(.InvalidToken))
            }
        }
    }

    private func composerParse(
        head: CharacterClass, composer: TokenComposer
    ) -> TokenKind {
        var follow = head
        repeat {
            if !composer.put(follow, ctx.cp.look()!) {
                return .Error(.InvalidToken)
            }
            ctx.consume(follow)
            follow = classifier.classify()
        } while !composer.isEndOfToken(follow)

        if let kind = composer.compose(follow) {
            return kind
        } else {
            return .Error(.InvalidToken)
        }
    }
}
