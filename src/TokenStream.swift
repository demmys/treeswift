struct Token {
    var kind: TokenKind!
    var source: String
    var lineNo: Int
    var charNo: Int

    init(lineNo: Int, charNo: Int) {
        self.lineNo = lineNo
        self.charNo = charNo
        source = ""
    }
}

class TokenStream {
    private let cs: CharacterStream!

    private var lineNo: Int = 1
    private var charNo: Int = 1

    init?(_ file: File) {
        cs = CharacterStream(file)
        if cs == nil {
            return nil
        }
    }

    func next() -> Token? {
        var composers = [IntegerLiteral()]
        var token = Token(lineNo: lineNo, charNo: charNo)

        while true {
            if let c = cs.next() {
                token.source.append(c)

                switch c {
                case "\n":
                    ++lineNo
                    charNo = 1
                case " ", "\t":
                    ++charNo
                case "\0", "\r", "\u{000b}", "\u{000c}":
                    break
                default:
                    composers = composers.filter({
                        $0.put(c)
                    })
                    ++charNo
                    continue
                }
                break
            } else {
                println("end of file")
                return nil
            }
        }

        var tokenKinds = composers.map({
            $0.compose()
        }).filter({
            $0 != nil
        })
        switch tokenKinds.count {
        case 0:
            println("error: \(token.source)")
            return nil
        case 1:
            token.kind = tokenKinds[0]
            return token
        default:
            println("ambiguous string: \(token.source)")
            return nil
        }
    }
}
