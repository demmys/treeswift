public enum Procedure {
    case DeclarationProcedure // (Declaration) TODO
    case OperationProcedure(Operation)
    case FlowProcedure(Flow)
    case FlowSwitchProcedure(FlowSwitch)
}

public enum Operation {
    case ExpressionOperation(Expression)
    case AssignmentOperation(Pattern, Expression)
    case BreakOperation(String?)
    case ContinueOperation(String?)
    case FallthroughOperation
    case ReturnOperation(Expression?)
    case ThrowOperation(Expression)
}

public class Flow {
    var pats: [PatternMatching]!
    var block: [Procedure]!
}

public class PatternMatching {
    var pat: Pattern!
    var exp: Expression?
    var rest: Expression?

    init() {}
    init(_ pat: Pattern, _ exp: Expression?, _ rest: Expression?) {
        self.pat = pat
        self.exp = exp
        self.rest = rest
    }
}

public class ForFlow : Flow {
    var label: String?
    var ini: ForInit?
    var fin: Operation?

    init(_ label: String?) {
        self.label = label
    }

    func setCond(c: Expression) {
        pats = [PatternMatching(.BooleanPattern, c, nil)]
    }
}

public enum ForInit {
    case VariableDeclaration // (Declaration) TODO
    case InitOperation(Operation)
}

public class ForInFlow : Flow {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }
}

public class WhileFlow : Flow {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }
}

public class RepeatWhileFlow : Flow {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }

    func setCond(c: Expression) {
        pats = [PatternMatching(.BooleanPattern, c, nil)]
    }
}

public class IfFlow : Flow {
    var label: String?
    var els: ElseClause?

    init(_ label: String?) {
        self.label = label
    }
}

public enum ElseClause {
    case Else([Procedure])
    case ElseIf(IfFlow)
}

public class GuardFlow : Flow {}

public class DeferFlow : Flow {}

public class DoFlow : Flow {
    var catches: [CatchFlow] = []
}

public class CatchFlow : Flow {}

public class FlowSwitch {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }
}

public class CaseFlow : Flow {}
