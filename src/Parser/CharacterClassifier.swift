enum CharacterClass {
    case EndOfFile, LineFeed, CarriageReturn, Space
    case Semicolon, Colon, Comma, Hash, Underscore, Atmark
    case LeftParenthesis, RightParenthesis
    case LeftBrace, RightBrace
    case LeftBracket, RightBracket
    // belows may be a part of word
    case Arrow
    case Dot, Equal, Digit
    case DoubleQuote, BackSlash
    case Dollar, BackQuote, IdentifierHead, IdentifierFollow
    case OperatorHead, DotOperatorHead, OperatorFollow
    // belows may be a reserved word
    case LessThan, GraterThan
    case Ampersand, Question, Exclamation
    // meaningless characters
    case LineCommentHead, BlockCommentHead, BlockCommentTail
    case Others
}

class CharacterClassifier {
    let cp: CharacterPeeper

    init(cp: CharacterPeeper) {
        self.cp = cp
    }

    func classify() -> CharacterClass {
        let character = cp.look()
        if let c = character {
            switch c {
            case "\n":
                return .LineFeed
            case "\r":
                return .CarriageReturn
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
            case "@":
                return .Atmark
            case "\"":
                return .DoubleQuote
            case "\\":
                return .BackSlash
            case "=":
                // token "=" cannot become a custom operator
                if let succ = cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Equal
            case "&":
                // token "&" will be distinguished from other operators
                // by the fact that of prefix operator is reserved
                if let succ = cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Ampersand
            case "?":
                // token "?" will be distinguished from other operators
                // by the fact that of prefix, infix and postfix operator is reserved
                if let succ = cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Question
            case "!":
                // token "!" will be distinguished from other operators
                // by the fact that of postfix operator is reserved
                if let succ = cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .Exclamation
            case "<":
                // token "<" will be distinguished from other operators
                // by the fact that of prefix operator is reserved
                if let succ = cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .LessThan
            case ">":
                // token ">" will be distinguished from other operators
                // by the fact that of postfix operator is reserved
                if let succ = cp.lookAhead() {
                    if isOperatorFollow(succ) || isOperatorHead(succ) {
                        return .OperatorHead
                    }
                }
                return .GraterThan
            case "-":
                // token "->" cannot become a custom operator
                if let succ = cp.lookAhead() {
                    if succ == ">" {
                        return .Arrow
                    }
                }
                return .OperatorHead
            case "_":
                // token "_" cannot become an identifier
                if let succ = cp.lookAhead() {
                    if isIdentifierFollow(succ) || isIdentifierHead(succ) {
                        return .IdentifierHead
                    }
                }
                return .Underscore
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
