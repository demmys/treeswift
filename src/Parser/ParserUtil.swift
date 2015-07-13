class ParserUtil {
    private let ts: TokenStream

    init(_ ts: TokenStream) {
        self.ts = ts
    }

    func find(candidates: [TokenKind], startIndex: Int = 0) -> (Int, TokenKind) {
        var i = startIndex
        var kind = ts.look(i).kind
        while kind != .EndOfFile {
            for c in candidates {
                if kind == c {
                    return (i, kind)
                }
            }
            kind = ts.look(++i).kind
        }
        return (i, .EndOfFile)
    }
}
