/*
typealias Label = String

enum Statement {
    // loop-statement, labeled-statement
    case For(ForCondition, [Statement], Label?)
    case ForIn(ForInCondition, [Statement], Label?)
    case While(WhileCondition, [Statement], Label?)
    case DoWhile(WhileCondition, [Statement], Label?)
    // branch-statement
    case If(IfCondition, [Statement], ElseClause?)
    // control-transfer-statement
    case Break(Label?)
    case Continue(Label?)
    case Return(Expression?)
}
*/

public enum ASTStructure {
    case Unimplemented
    case Optional
    case Terminal(Token)
    /*
    case Statement(Statement)
    case Statements([Statement])
    case TopLevelDeclaration([Statement]?)
    */
}
