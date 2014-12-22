enum CharacterClass {
    case EndOfFile, LineFeed, Space
    case Semicolon, Colon, Comma, Arrow, Hash, Underscore, Dot
    case AssignmentOperator
    case LeftParenthesis, RightParenthesis
    case LeftBrace, RightBrace
    case LeftBracket, RightBracket
    // context depended classes
    case LessThan, GraterThan
    case Ampersand, Question, Exclamation, Dollar, BackQuote
    case OperatorHead, DotOperatorHead, OperatorFollow
    case IdentifierHead, IdentifierFollow, Digit
    // meaningless classes
    case LineCommentHead, BlockCommentHead, BlockCommentTail
    case Others
}

enum IdentifierKind {
    case Identifier(String)
    case QuotedIdentifier(String)
    case ImplicitParameter(Int)
}

enum TokenKind {
    case Error(ErrorMessage)
    case EndOfFile, LineFeed
    case Semicolon, Colon, Comma, Arrow, Hash, Underscore, Dot
    case AssignmentOperator
    case LeftParenthesis, RightParenthesis
    case LeftBrace, RightBrace
    case LeftBracket, RightBracket
    case PrefixLessThan, PostfixGraterThan
    case PrefixAmpersand
    case PrefixQuestion, BinaryQuestion, PostfixQuestion
    case PostfixExclamation
    case BinaryOperator(String), PrefixOperator(String), PostfixOperator(String)
    case Identifier(IdentifierKind)
    case IntegerLiteral(Int)
    case As, Associativity, Break, Continue, Do, Else, For, Func, If, Infix, In
    case Inout, Is, Let, Left, None, Operator, Prefix, Postfix, Precedence
    case Return, Var, Right, Typealias, While
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
    case .Colon:
        switch b {
        case .Colon:
            return true
        default:
            return false
        }
    case .Comma:
        switch b {
        case .Comma:
            return true
        default:
            return false
        }
    case .Arrow:
        switch b {
        case .Arrow:
            return true
        default:
            return false
        }
    case .Hash:
        switch b {
        case .Hash:
            return true
        default:
            return false
        }
    case .Underscore:
        switch b {
        case .Underscore:
            return true
        default:
            return false
        }
    case .PrefixLessThan:
        switch b {
        case .PrefixLessThan:
            return true
        default:
            return false
        }
    case .PostfixGraterThan:
        switch b {
        case .PostfixGraterThan:
            return true
        default:
            return false
        }
    case .PrefixAmpersand:
        switch b {
        case .PrefixAmpersand:
            return true
        default:
            return false
        }
    case .PrefixQuestion:
        switch b {
        case .PrefixQuestion:
            return true
        default:
            return false
        }
    case .BinaryQuestion:
        switch b {
        case .BinaryQuestion:
            return true
        default:
            return false
        }
    case .PostfixQuestion:
        switch b {
        case .PostfixQuestion:
            return true
        default:
            return false
        }
    case .PostfixExclamation:
        switch b {
        case .PostfixExclamation:
            return true
        default:
            return false
        }
    case .Dot:
        switch b {
        case .Dot:
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
    case .LeftBrace:
        switch b {
        case .LeftBrace:
            return true
        default:
            return false
        }
    case .RightBrace:
        switch b {
        case .RightBrace:
            return true
        default:
            return false
        }
    case .LeftBracket:
        switch b {
        case .LeftBracket:
            return true
        default:
            return false
        }
    case .RightBracket:
        switch b {
        case .RightBracket:
            return true
        default:
            return false
        }
    case .Identifier:
        switch b {
        case .Identifier:
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
    case .AssignmentOperator:
        switch b {
        case .AssignmentOperator:
            return true
        default:
            return false
        }
    case .For:
        switch b {
        case .For:
            return true
        default:
            return false
        }
    case .While:
        switch b {
        case .While:
            return true
        default:
            return false
        }
    case .Do:
        switch b {
        case .Do:
            return true
        default:
            return false
        }
    case .If:
        switch b {
        case .If:
            return true
        default:
            return false
        }
    case .Else:
        switch b {
        case .Else:
            return true
        default:
            return false
        }
    case .Break:
        switch b {
        case .Break:
            return true
        default:
            return false
        }
    case .Continue:
        switch b {
        case .Continue:
            return true
        default:
            return false
        }
    case .Return:
        switch b {
        case .Return:
            return true
        default:
            return false
        }
    case .Let:
        switch b {
        case .Let:
            return true
        default:
            return false
        }
    case .Var:
        switch b {
        case .Var:
            return true
        default:
            return false
        }
    case .Func:
        switch b {
        case .Func:
            return true
        default:
            return false
        }
    case .Inout:
        switch b {
        case .Inout:
            return true
        default:
            return false
        }
    case .Prefix:
        switch b {
        case .Prefix:
            return true
        default:
            return false
        }
    case .Postfix:
        switch b {
        case .Postfix:
            return true
        default:
            return false
        }
    case .Infix:
        switch b {
        case .Infix:
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
    case .Precedence:
        switch b {
        case .Precedence:
            return true
        default:
            return false
        }
    case .Associativity:
        switch b {
        case .Associativity:
            return true
        default:
            return false
        }
    case .Left:
        switch b {
        case .Left:
            return true
        default:
            return false
        }
    case .Right:
        switch b {
        case .Right:
            return true
        default:
            return false
        }
    case .None:
        switch b {
        case .None:
            return true
        default:
            return false
        }
    case .Is:
        switch b {
        case .Is:
            return true
        default:
            return false
        }
    case .As:
        switch b {
        case .As:
            return true
        default:
            return false
        }
    case .In:
        switch b {
        case .In:
            return true
        default:
            return false
        }
    case .Let:
        switch b {
        case .Let:
            return true
        default:
            return false
        }
    case .Typealias:
        switch b {
        case .Typealias:
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
    func look(Int) -> Token
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

        let head = classified ?? classify()
        switch head {
        case .EndOfFile:
            return produce(.EndOfFile)
        case .LineFeed:
            if ctx.prev == .LineFeed {
                // remove duplicated line feed
                while true {
                    let cc = classify()
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
        case .Space:
            ctx.consume(consumed: head)
            // remove duplicated space
            while true {
                let cc = classify()
                if cc == .Space {
                    ctx.consume()
                } else {
                    ctx.reset()
                    return load(classified: cc)
                }
            }
        case .Semicolon:
            ctx.consume(consumed: head)
            return produce(.Semicolon)
        case .Colon:
            ctx.consume(consumed: head)
            return produce(.Colon)
        case .Comma:
            ctx.consume(consumed: head)
            return produce(.Comma)
        case .Arrow:
            ctx.consume(consumed: head, n: 2)
            return produce(.Arrow)
        case .Hash:
            ctx.consume(consumed: head)
            return produce(.Hash)
        case .Underscore:
            ctx.consume(consumed: head)
            return produce(.Underscore)
        case .Dot:
            ctx.consume(consumed: head)
            return produce(.Dot)
        case .AssignmentOperator:
            ctx.consume(consumed: head)
            return produce(.AssignmentOperator)
        case .LeftParenthesis:
            ctx.consume(consumed: head)
            return produce(.LeftParenthesis)
        case .RightParenthesis:
            ctx.consume(consumed: head)
            return produce(.RightParenthesis)
        case .LeftBrace:
            ctx.consume(consumed: head)
            return produce(.LeftBrace)
        case .RightBrace:
            ctx.consume(consumed: head)
            return produce(.RightBrace)
        case .LeftBracket:
            ctx.consume(consumed: head)
            return produce(.LeftBracket)
        case .RightBracket:
            ctx.consume(consumed: head)
            return produce(.RightBracket)
        case .LineCommentHead:
            ctx.consume(n: 2)
            while true {
                let cc = classify()
                switch cc {
                case .LineFeed, .EndOfFile:
                    // a comment produces nothing
                    ctx.reset()
                    return load(classified: cc)
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
                switch classify() {
                case .BlockCommentHead:
                    ctx.consume(n: 2)
                    ++depth
                case .BlockCommentTail:
                    ctx.consume(consumed: .BlockCommentTail, n: 2)
                    --depth
                case .EndOfFile:
                    info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
                    return produce(.Error(.UnexpectedEOF))
                default:
                    // ignore comment characters
                    ctx.consume()
                }
            }
            // a comment produces nothing
            ctx.reset()
            return load()
        case .BlockCommentTail:
            info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
            ctx.consume(n: 2)
            return produce(.Error(.ReservedToken))
        case .OperatorFollow, .IdentifierFollow, .Others:
            info = SourceInfo(lineNo: ctx.lineNo, charNo: ctx.charNo)
            ctx.consume()
            return produce(.Error(.InvalidToken))
        case .LessThan, .GraterThan, .Ampersand, .Question, .Exclamation:
            return produce(composerParse(
                head,
                composer: OperatorComposer(prev: ctx.prev),
                isEndOfToken: { (follow) in true }
            ))
        case .OperatorHead, .DotOperatorHead:
            return produce(composerParse(
                head,
                composer: OperatorComposer(prev: ctx.prev),
                isEndOfToken: { (follow) in
                    switch follow {
                    case .OperatorHead, .OperatorFollow:
                        return false
                    case .DotOperatorHead, .Dot:
                        switch head {
                        case .DotOperatorHead:
                            return false
                        default:
                            return true
                        }
                    default:
                        return true
                    }
                }
            ))
        case .Dollar:
            return produce(composerParse(
                head,
                composer: IdentifierComposer(),
                isEndOfToken: { (follow) in
                    switch follow {
                    case .Digit:
                        return false
                    default:
                        return true
                    }
                }
            ))
        case .BackQuote:
            var lastToken = false
            return produce(composerParse(
                head,
                composer: IdentifierComposer(),
                isEndOfToken: { (follow) in
                    if lastToken {
                        return true
                    }
                    switch follow {
                    case .BackQuote:
                        lastToken = true
                    default:
                        break
                    }
                    return false
                }
            ))
        case .Digit:
            return produce(composerParse(
                head,
                composer: IntegerLiteralComposer(),
                isEndOfToken: { (follow) in
                    switch follow {
                    case .Digit, .IdentifierHead:
                        return false
                    default:
                        return true
                    }
                }
            ))
        case .IdentifierHead:
            var composer = IdentifierComposer()
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
                reservedWords = [WordLiteralComposer("continue", .Continue)]
            case "d":
                reservedWords = [WordLiteralComposer("do", .Do)]
            case "e":
                reservedWords = [WordLiteralComposer("else", .Else)]
            case "f":
                reservedWords = [
                    WordLiteralComposer("for", .For),
                    WordLiteralComposer("func", .Func)
                ]
            case "i":
                reservedWords = [
                    WordLiteralComposer("if", .If),
                    WordLiteralComposer("infix", .Infix),
                    WordLiteralComposer("in", .In),
                    WordLiteralComposer("inout", .Inout),
                    WordLiteralComposer("is", .Is)
                ]
            case "l":
                reservedWords = [
                    WordLiteralComposer("left", .Left),
                    WordLiteralComposer("let", .Let)
                ]
            case "n":
                reservedWords = [WordLiteralComposer("none", .None)]
            case "o":
                reservedWords = [WordLiteralComposer("operator", .Operator)]
            case "p":
                reservedWords = [
                    WordLiteralComposer("postfix", .Postfix),
                    WordLiteralComposer("precedence", .Precedence),
                    WordLiteralComposer("prefix", .Prefix)
                ]
            case "r":
                reservedWords = [
                    WordLiteralComposer("return", .Return),
                    WordLiteralComposer("right", .Right)
                ]
            case "t":
                reservedWords = [WordLiteralComposer("typealias", .Typealias)]
            case "v":
                reservedWords = [WordLiteralComposer("var", .Var)]
            case "w":
                reservedWords = [WordLiteralComposer("while", .While)]
            default:
                break
            }
            var follow = head
            var endOfToken = false
            do {
                composer.put(follow, ctx.cp.look()!)
                reservedWords = reservedWords?.filter({
                    $0.put(follow, self.ctx.cp.look()!)
                })
                ctx.consume(consumed: follow)
                follow = classify()
                switch follow {
                case .IdentifierHead, .IdentifierFollow, .Digit, .Underscore:
                    break
                default:
                    endOfToken = true
                }
            } while !endOfToken

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

    private func composerParse(head: CharacterClass,
                               composer: TokenComposer,
                               isEndOfToken: CharacterClass -> Bool) -> TokenKind {
        var follow = head
        var endOfToken = false
        do {
            if !composer.put(follow, ctx.cp.look()!) {
                return .Error(.InvalidToken)
            }
            ctx.consume(consumed: follow)
            follow = classify()
            if isEndOfToken(follow) {
                endOfToken = true
            }
        } while !endOfToken

        if let kind = composer.compose(follow) {
            return kind
        } else {
            return .Error(.InvalidToken)
        }
    }

    // classify would not consume characters
    private func classify() -> CharacterClass {
        let character = ctx.cp.look()
        if let c = character {
            switch c {
            case "\n":
                return .LineFeed
            case ";":
                return .Semicolon
            case ":":
                return .Colon
            case ",":
                return .Comma
            case "(":
                return .LeftParenthesis
            case ")":
                return .RightParenthesis
            case "{":
                return .LeftBrace
            case "}":
                return .RightBrace
            case "[":
                return .LeftBracket
            case "]":
                return .RightBracket
            case "`":
                return .BackQuote
            case "#":
                return .Hash
            case "$":
                return .Dollar
            case "=":
                // token "=" cannot become a custom operator
                if let succ = ctx.cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .AssignmentOperator
            case "&":
                // token "&" will be distinguished from other operators
                // by the fact that of prefix operator is reserved
                if let succ = ctx.cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Ampersand
            case "?":
                // token "?" will be distinguished from other operators
                // by the fact that of prefix, infix and postfix operator is reserved
                if let succ = ctx.cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Question
            case "!":
                // token "!" will be distinguished from other operators
                // by the fact that of postfix operator is reserved
                if let succ = ctx.cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Exclamation
            case "<":
                // token "<" will be distinguished from other operators
                // by the fact that of prefix operator is reserved
                if let succ = ctx.cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .LessThan
            case ">":
                // token ">" will be distinguished from other operators
                // by the fact that of postfix operator is reserved
                if let succ = ctx.cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .GraterThan
            case "-":
                // token "->" cannot become a custom operator
                if let succ = ctx.cp.lookAhead() {
                    if succ == ">" {
                        return .Arrow
                    }
                }
                return .OperatorHead
            case "_":
                // token "_" cannot become an identifier
                if let succ = ctx.cp.lookAhead() {
                    if isIdentifierFollow(succ) || isIdentifierHead(succ) {
                        return .IdentifierHead
                    }
                }
                return .Underscore
            case ".":
                if let succ = ctx.cp.lookAhead() {
                    if succ == "." {
                        return .DotOperatorHead
                    }
                }
                return .Dot
            case "/":
                if let succ = ctx.cp.lookAhead() {
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
                if let succ = ctx.cp.lookAhead() {
                    if succ == "/" {
                        return .BlockCommentTail
                    }
                }
                return .OperatorHead
            case "0"..."9":
                return .Digit
            default:
                if isSpace(c) {
                    return .Space
                }
                if isIdentifierFollow(c) {
                    return .IdentifierFollow
                }
                if isOperatorFollow(c) {
                    return .OperatorFollow
                }
                if isOperatorHead(c) {
                    return .OperatorHead
                }
                if isIdentifierHead(c) {
                    return .IdentifierHead
                }
                return .Others
            }
        } else {
            return .EndOfFile
        }
    }

    private func isSpace(c: Character) -> Bool {
        switch c {
        case " ", "\t", "\0", "\r", "\u{000b}", "\u{000c}":
            return true
        default:
            return false
        }
    }

    private func isOperatorHead(c: Character) -> Bool {
        switch c {
        case "/", "=", "-", "+", "!", "*", "%", "<", ">", "|", "^", "~", "?",
             "\u{00a1}"..."\u{00a7}", "\u{00a9}", "\u{00ab}", "\u{00ac}",
             "\u{00ae}", "\u{00b0}", "\u{00b1}", "\u{00b6}", "\u{00bb}",
             "\u{00bf}", "\u{00d7}", "\u{00f7}", "\u{2016}", "\u{2017}",
             "\u{2020}"..."\u{2027}", "\u{2030}"..."\u{203e}",
             "\u{2041}"..."\u{2053}", "\u{2055}"..."\u{205e}",
             "\u{2190}"..."\u{23ff}", "\u{2500}"..."\u{2775}",
             "\u{2794}"..."\u{2bff}", "\u{2e00}"..."\u{2e7f}",
             "\u{3001}"..."\u{3003}", "\u{3008}"..."\u{3030}":
            return true
        default:
            return false
        }
    }

    private func isOperatorFollow(c: Character) -> Bool {
        switch c {
        case "\u{0300}"..."\u{036f}", "\u{1dc0}"..."\u{1dff}",
             "\u{20d0}"..."\u{20ff}", "\u{fe00}"..."\u{fe0f}",
             "\u{fe20}"..."\u{fe2f}", "\u{e0100}"..."\u{e01ef}":
            return true
        default:
            return false
        }
    }

    private func isIdentifierHead(c: Character) -> Bool {
        switch c {
        case "a"..."z", "A"..."Z", "_",
             "\u{00A8}", "\u{00AA}", "\u{00AD}", "\u{00AF}",
             "\u{00B2}"..."\u{00B5}", "\u{00B7}"..."\u{00BA}",
             "\u{00BC}"..."\u{00BE}", "\u{00C0}"..."\u{00D6}",
             "\u{00D8}"..."\u{00F0}", "\u{00F1}"..."\u{00F6}",
             "\u{00F8}"..."\u{00FE}", "\u{00FF}",
             "\u{0100}"..."\u{02FF}", "\u{0370}"..."\u{167F}",
             "\u{1681}"..."\u{180D}", "\u{180F}"..."\u{1DBF}",
             "\u{1E00}"..."\u{1FFF}", "\u{200B}"..."\u{200D}",
             "\u{202A}"..."\u{202E}", "\u{203F}"..."\u{2040}",
             "\u{2054}", "\u{2060}"..."\u{206F}", "\u{2070}"..."\u{20CF}",
             "\u{2100}"..."\u{218F}", "\u{2460}"..."\u{24FF}",
             "\u{2776}"..."\u{2793}", "\u{2C00}"..."\u{2DFF}",
             "\u{2E80}"..."\u{2FFF}", "\u{3004}"..."\u{3007}",
             "\u{3021}"..."\u{302F}", "\u{3031}"..."\u{303F}",
             "\u{3040}"..."\u{D7FF}", "\u{F900}"..."\u{FD3D}",
             "\u{FD40}"..."\u{FDCF}", "\u{FDF0}"..."\u{FE1F}",
             "\u{FE30}"..."\u{FE44}", "\u{FE47}"..."\u{FFFD}",
             "\u{10000}"..."\u{1FFFD}", "\u{20000}"..."\u{2FFFD}",
             "\u{30000}"..."\u{3FFFD}", "\u{40000}"..."\u{4FFFD}",
             "\u{50000}"..."\u{5FFFD}", "\u{60000}"..."\u{6FFFD}",
             "\u{70000}"..."\u{7FFFD}", "\u{80000}"..."\u{8FFFD}",
             "\u{90000}"..."\u{9FFFD}", "\u{A0000}"..."\u{AFFFD}",
             "\u{B0000}"..."\u{BFFFD}", "\u{C0000}"..."\u{CFFFD}",
             "\u{D0000}"..."\u{DFFFD}", "\u{E0000}"..."\u{EFFFD}":
            return true
        default:
            return false
        }
    }

    private func isIdentifierFollow(c: Character) -> Bool {
        switch c {
        case "0"..."9", "\u{0300}"..."\u{036F}", "\u{1DC0}"..."\u{1DFF}",
             "\u{20D0}"..."\u{20FF}", "\u{FE20}"..."\u{FE2F}":
            return true
        default:
            return false
        }
    }
}
