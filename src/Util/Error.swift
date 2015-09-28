import Darwin

public struct SourceInfo {
    public var lineNo: Int
    public var charNo: Int
    public var source: String?

    public init(lineNo: Int, charNo: Int, source: String? = nil) {
        self.lineNo = lineNo
        self.charNo = charNo
        self.source = source
    }
}

public protocol SourceTrackable {
    public var sourceInfo: SourceInfo { get }
}

public enum ErrorKind : String {
    case Fatal = "fatal"
    case Error = "error"
    case Warning = "warning"
}

public typealias Error = (ErrorKind, ErrorMessage, SourceInfo?)

public enum ErrorReport : ErrorType {
    case Fatal(ErrorReporter)
    case Full(ErrorReporter)
}

public class ErrorReporter {
    private static var errors: [Error] = []

    public static func hasErrors() -> Bool {
        return errors.count > 0
    }

    private static func append(
        kind: ErrorKind, message: ErrorMessage, source: SourceTrackable?
    ) throws {
        errors.append((kind, message, source?.sourceInfo))
        if case .Fatal = kind {
            throw ErrorReport.Fatal(self)
        }
        if errors.count > 15 {
            throw ErrorReport.Full(self)
        }
    }
    public static func fatal(message: ErrorMessage, _ source: SourceTrackable?) throws {
        try append(.Fatal, message, source)
    }
    public static func error(message: ErrorMessage, _ source: SourceTrackable?) throws {
        try append(.Error, message, source)
    }
    public static func warning(message: ErrorMessage, _ source: SourceTrackable?) throws {
        try append(.Warning, message, source)
    }

    public static func report() {
        for (kind, msg, info) in errors {
            if let i = info {
                print("\(kind): \(i.lineNo):\(i.charNo) \(msg)\n\(i.source!)")
            } else {
                print("\(kind): \(msg)")
            }
        }
    }
}

public enum ErrorMessage {
    case FileNotFound(String)
    case FileCanNotRead(String)
    // System errors
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
    case ExpectedUnderscore = "Expected underscore"
    case ExpectedOperator = "Expected the word operator"
    case ExpectedIn = "Expected the word in"
    case ExpectedWhile = "Expected the word while"

    public func format() -> String {
        switch self {
        case let .FileNotFound(name):
            return "No such a file: \(name)"
        case let .FileCanNotRead(name):
            return "File cannot read: \(name)"
        }
    }
}
