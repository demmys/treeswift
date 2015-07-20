import Util

public enum ModifierKind {
    case Class, Convenience, Dynamic, Final, Infix, Lazy, Mutating, Nonmutating
    case Optional, Override, Postfix, Prefix, Required, Static
    case Unowned, UnownedSafe, UnownedUnsafe, Weak
    case Internal, Private, Public
    case InternalSet, PrivateSet, PublicSet
}

public enum TokenKind : Equatable {
    case Error(ErrorMessage)
    case EndOfFile, LineFeed
    case Semicolon, Colon, Comma, Hash, Underscore, Atmark
    case LeftParenthesis, RightParenthesis
    case LeftBrace, RightBrace
    case LeftBracket, RightBracket
    case AssignmentOperator, Dot, Arrow
    case PrefixLessThan, PostfixGraterThan
    case PrefixAmpersand
    case PrefixQuestion, BinaryQuestion, PostfixQuestion
    case PostfixExclamation
    case PrefixOperator(String), BinaryOperator(String), PostfixOperator(String)
    case Identifier(String), ImplicitParameterName(Int)
    case IntegerLiteral(Int64, decimalDigits: Bool)
    case FloatingPointLiteral(Double)
    case StringLiteral(String)
    case BooleanLiteral(Bool)
    case Modifier(ModifierKind)
    case Attribute(String)
    case As, Associativity, Break, Continue, Do, Else, For, Func, If, Infix
    case In, InOut, Is, Let, Left, Nil, None, Operator, Prefix, Postfix
    case Precedence, Return, Right, Typealias, Unowned, Var, Weak, While
}

public func ==(lhs: TokenKind, rhs: TokenKind) -> Bool {
    switch lhs {
    case .Error:
        if case .Error = rhs {
            return true
        }
    case .EndOfFile:
        if case .EndOfFile = rhs {
            return true
        }
    case .LineFeed:
        if case .LineFeed = rhs {
            return true
        }
    case .Semicolon:
        if case .Semicolon = rhs {
            return true
        }
    case .Colon:
        if case .Colon = rhs {
            return true
        }
    case .Comma:
        if case .Comma = rhs {
            return true
        }
    case .Arrow:
        if case .Arrow = rhs {
            return true
        }
    case .Hash:
        if case .Hash = rhs {
            return true
        }
    case .Underscore:
        if case .Underscore = rhs {
            return true
        }
    case .Atmark:
        if case .Atmark = rhs {
            return true
    }
    case .Dot:
        if case .Dot = rhs {
            return true
        }
    case .AssignmentOperator:
        if case .AssignmentOperator = rhs {
            return true
        }
    case .LeftParenthesis:
        if case .LeftParenthesis = rhs {
            return true
        }
    case .RightParenthesis:
        if case .RightParenthesis = rhs {
            return true
        }
    case .LeftBrace:
        if case .LeftBrace = rhs {
            return true
        }
    case .RightBrace:
        if case .RightBrace = rhs {
            return true
        }
    case .LeftBracket:
        if case .LeftBracket = rhs {
            return true
        }
    case .RightBracket:
        if case .RightBracket = rhs {
            return true
        }
    case .PrefixLessThan:
        if case .PrefixLessThan = rhs {
            return true
        }
    case .PostfixGraterThan:
        if case .PostfixGraterThan = rhs {
            return true
        }
    case .PrefixAmpersand:
        if case .PrefixAmpersand = rhs {
            return true
        }
    case .PrefixQuestion:
        if case .PrefixQuestion = rhs {
            return true
        }
    case .BinaryQuestion:
        if case .BinaryQuestion = rhs {
            return true
        }
    case .PostfixQuestion:
        if case .PostfixQuestion = rhs {
            return true
        }
    case .PostfixExclamation:
        if case .PostfixExclamation = rhs {
            return true
        }
    case .PrefixOperator:
        if case .PrefixOperator = rhs {
            return true
        }
    case .BinaryOperator:
        if case .BinaryOperator = rhs {
            return true
        }
    case .PostfixOperator:
        if case .PostfixOperator = rhs {
            return true
        }
    case .Identifier:
        if case .Identifier = rhs {
            return true
        }
    case .IntegerLiteral:
        if case .IntegerLiteral = rhs {
            return true
        }
    case .FloatingPointLiteral:
        if case .FloatingPointLiteral = rhs {
            return true
        }
    case .StringLiteral:
        if case .StringLiteral = rhs {
            return true
        }
    case .BooleanLiteral:
        if case .BooleanLiteral = rhs {
            return true
        }
    case .Modifier:
        if case .Modifier = rhs {
            return true
        }
    case .Attribute:
        if case .Attribute = rhs {
            return true
        }
    case .As:
        if case .As = rhs {
            return true
        }
    case .Associativity:
        if case .Associativity = rhs {
            return true
        }
    case .Break:
        if case .Break = rhs {
            return true
        }
    case .Continue:
        if case .Continue = rhs {
            return true
        }
    case .Do:
        if case .Do = rhs {
            return true
        }
    case .Else:
        if case .Else = rhs {
            return true
        }
    case .For:
        if case .For = rhs {
            return true
        }
    case .Func:
        if case .Func = rhs {
            return true
        }
    case .If:
        if case .If = rhs {
            return true
        }
    case .Infix:
        if case .Infix = rhs {
            return true
        }
    case .In:
        if case .In = rhs {
            return true
        }
    case .InOut:
        if case .InOut = rhs {
            return true
        }
    case .Is:
        if case .Is = rhs {
            return true
        }
    case .Let:
        if case .Let = rhs {
            return true
        }
    case .Left:
        if case .Left = rhs {
            return true
        }
    case .Nil:
        if case .Nil = rhs {
            return true
        }
    case .None:
        if case .None = rhs {
            return true
        }
    case .Operator:
        if case .Operator = rhs {
            return true
        }
    case .Prefix:
        if case .Prefix = rhs {
            return true
        }
    case .Postfix:
        if case .Postfix = rhs {
            return true
        }
    case .Precedence:
        if case .Precedence = rhs {
            return true
        }
    case .Return:
        if case .Return = rhs {
            return true
        }
    case .Var:
        if case .Var = rhs {
            return true
        }
    case .Right:
        if case .Right = rhs {
            return true
        }
    case .Typealias:
        if case .Typealias = rhs {
            return true
        }
    case .While:
        if case .While = rhs {
            return true
        }
    case .Weak:
        if case .Weak = rhs {
            return true
        }
    case .Unowned:
        if case .Unowned = rhs {
            return true
        }
    }
    return false
}
