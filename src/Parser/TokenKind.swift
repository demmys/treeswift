import Util

public enum IdentifierKind {
    case Identifier(String)
    case QuotedIdentifier(String)
    case ImplicitParameter(Int)
}

public enum TokenKind : Equatable {
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
    case PrefixOperator(String), BinaryOperator(String), PostfixOperator(String)
    case Identifier(IdentifierKind)
    case IntegerLiteral(Int, decimalDigits: Bool)
    case BooleanLiteral(Bool)
    case As, Associativity, Break, Continue, Do, Else, For, Func, If, Infix
    case In, Inout, Is, Let, Left, Nil, None, Operator, Prefix, Postfix
    case Precedence, Return, Var, Right, Typealias, While
}

public func ==(lhs: TokenKind, rhs: TokenKind) -> Bool {
    switch lhs {
    case .Error:
        switch rhs {
        case .Error: return true
        default: return false
        }
    case .EndOfFile:
        switch rhs {
        case .EndOfFile: return true
        default: return false
        }
    case .LineFeed:
        switch rhs {
        case .LineFeed: return true
        default: return false
        }
    case .Semicolon:
        switch rhs {
        case .Semicolon: return true
        default: return false
        }
    case .Colon:
        switch rhs {
        case .Colon: return true
        default: return false
        }
    case .Comma:
        switch rhs {
        case .Comma: return true
        default: return false
        }
    case .Arrow:
        switch rhs {
        case .Arrow: return true
        default: return false
        }
    case .Hash:
        switch rhs {
        case .Hash: return true
        default: return false
        }
    case .Underscore:
        switch rhs {
        case .Underscore: return true
        default: return false
        }
    case .Dot:
        switch rhs {
        case .Dot: return true
        default: return false
        }
    case .AssignmentOperator:
        switch rhs {
        case .AssignmentOperator: return true
        default: return false
        }
    case .LeftParenthesis:
        switch rhs {
        case .LeftParenthesis: return true
        default: return false
        }
    case .RightParenthesis:
        switch rhs {
        case .RightParenthesis: return true
        default: return false
        }
    case .LeftBrace:
        switch rhs {
        case .LeftBrace: return true
        default: return false
        }
    case .RightBrace:
        switch rhs {
        case .RightBrace: return true
        default: return false
        }
    case .LeftBracket:
        switch rhs {
        case .LeftBracket: return true
        default: return false
        }
    case .RightBracket:
        switch rhs {
        case .RightBracket: return true
        default: return false
        }
    case .PrefixLessThan:
        switch rhs {
        case .PrefixLessThan: return true
        default: return false
        }
    case .PostfixGraterThan:
        switch rhs {
        case .PostfixGraterThan: return true
        default: return false
        }
    case .PrefixAmpersand:
        switch rhs {
        case .PrefixAmpersand: return true
        default: return false
        }
    case .PrefixQuestion:
        switch rhs {
        case .PrefixQuestion: return true
        default: return false
        }
    case .BinaryQuestion:
        switch rhs {
        case .BinaryQuestion: return true
        default: return false
        }
    case .PostfixQuestion:
        switch rhs {
        case .PostfixQuestion: return true
        default: return false
        }
    case .PostfixExclamation:
        switch rhs {
        case .PostfixExclamation: return true
        default: return false
        }
    case .PrefixOperator:
        switch rhs {
        case .PrefixOperator: return true
        default: return false
        }
    case .BinaryOperator:
        switch rhs {
        case .BinaryOperator: return true
        default: return false
        }
    case .PostfixOperator:
        switch rhs {
        case .PostfixOperator: return true
        default: return false
        }
    case .Identifier:
        switch rhs {
        case .Identifier: return true
        default: return false
        }
    case .IntegerLiteral:
        switch rhs {
        case .IntegerLiteral: return true
        default: return false
        }
    case .BooleanLiteral:
        switch rhs {
        case .BooleanLiteral: return true
        default: return false
        }
    case .As:
        switch rhs {
        case .As: return true
        default: return false
        }
    case .Associativity:
        switch rhs {
        case .Associativity: return true
        default: return false
        }
    case .Break:
        switch rhs {
        case .Break: return true
        default: return false
        }
    case .Continue:
        switch rhs {
        case .Continue: return true
        default: return false
        }
    case .Do:
        switch rhs {
        case .Do: return true
        default: return false
        }
    case .Else:
        switch rhs {
        case .Else: return true
        default: return false
        }
    case .For:
        switch rhs {
        case .For: return true
        default: return false
        }
    case .Func:
        switch rhs {
        case .Func: return true
        default: return false
        }
    case .If:
        switch rhs {
        case .If: return true
        default: return false
        }
    case .Infix:
        switch rhs {
        case .Infix: return true
        default: return false
        }
    case .In:
        switch rhs {
        case .In: return true
        default: return false
        }
    case .Inout:
        switch rhs {
        case .Inout: return true
        default: return false
        }
    case .Is:
        switch rhs {
        case .Is: return true
        default: return false
        }
    case .Let:
        switch rhs {
        case .Let: return true
        default: return false
        }
    case .Left:
        switch rhs {
        case .Left: return true
        default: return false
        }
    case .Nil:
        switch rhs {
        case .Nil: return true
        default: return false
        }
    case .None:
        switch rhs {
        case .None: return true
        default: return false
        }
    case .Operator:
        switch rhs {
        case .Operator: return true
        default: return false
        }
    case .Prefix:
        switch rhs {
        case .Prefix: return true
        default: return false
        }
    case .Postfix:
        switch rhs {
        case .Postfix: return true
        default: return false
        }
    case .Precedence:
        switch rhs {
        case .Precedence: return true
        default: return false
        }
    case .Return:
        switch rhs {
        case .Return: return true
        default: return false
        }
    case .Var:
        switch rhs {
        case .Var: return true
        default: return false
        }
    case .Right:
        switch rhs {
        case .Right: return true
        default: return false
        }
    case .Typealias:
        switch rhs {
        case .Typealias: return true
        default: return false
        }
    case .While:
        switch rhs {
        case .While: return true
        default: return false
        }
    }
}

func !=(a: TokenKind, b: TokenKind) -> Bool {
    return !(a == b)
}
