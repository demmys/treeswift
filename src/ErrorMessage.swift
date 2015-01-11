import Darwin

struct SourceInfo {
    var lineNo: Int
    var charNo: Int
    var source: String?

    init(lineNo: Int, charNo: Int, source: String? = nil) {
        self.lineNo = lineNo
        self.charNo = charNo
        self.source = source
    }
}

enum ErrorMessage: String {
    // System errors
    case NoInputFile = "No input file"
    case FileNotFound = "File not found"
    case InvalidFileType = "The file is not a textfile"
    // Lexical errors
    case UnexpectedEOF = "Unexpected end of file"
    case InvalidToken = "Invalid token"
    case AmbiguousToken = "Ambiguous token"
    case ReservedToken = "Reserved token"
    // Syntax errors
    case UnexpectedSymbol = "Unexpected Symbol"
    case ExpectedEndOfFile = "Expected end of file"
    case ExpectedIdentifier = "Expected identifier"
    case ExpectedIntegerLiteral = "Expected integer literal"
    case ExpectedEndOfStatement = "Expected line feed or semicolon at the end of statement"
    case ExpectedBinaryOperator = "Expected binary operator"
    case ExpectedPrefixOperator = "Expected prefix operator"
    case ExpectedPostfixOperator = "Expected postfix operator"
    case ExpectedAssignmentOperator = "Expected assignment operator"
    case ExpectedLeftParenthesis = "Expected left parenthesis"
    case ExpectedRightParenthesis = "Expected right parenthesis"
    case ExpectedRightBrace = "Expected right brace"
    case ExpectedLeftBrace = "Expected left brace"
    case ExpectedRightBracket = "Expected right bracket"
    case ExpectedColon = "Expected colon"
    case ExpectedSemicolon = "Expected semicolon"
    case ExpectedOperator = "Expected the word operator"
    case ExpectedIn = "Expected the word in"
    case ExpectedWhile = "Expected the word while"

    func print(target: String, info: SourceInfo? = nil) {
        var message = "error: \(self.rawValue)"
        if let i = info {
            message = "\(target):\(i.lineNo):\(i.charNo) \(message)"
            if let s = i.source {
                message = "\(message)\n\t\(s)\n"
            }
        }
        printStderr(message)
    }

    private func printStderr(message: String) {
        fputs(message, stderr)
    }
}
