public enum Procedure {
    case DeclarationProcedure(Declaration)
    case FlowSwitchProcedure(FlowSwitch)
    case FlowProcedure(Flow)
    case OperationProcedure(Operation)
}

public enum Operation {
    case ExpressionOperation(Expression)
    case AssignmentOperation(Pattern, Expression)
    case BreakOperation(String?)
    case ContinueOperation(String?)
    case FallthroughOperation
    case ReturnOperation(ReturnValue)
    case ThrowOperation(Expression)
}

public class ReturnValue : Typeable {
    public var type = TypeManager()
    public let exp: Expression?

    public init(_ e: Expression?) {
        exp = e
    }
}

public class Flow : ScopeTrackable {
    public var pats: [PatternMatching]!
    public var block: [Procedure]!
    public var associatedScope: Scope!

    public init() {}

    public var scope: Scope { return associatedScope }
}

public class PatternMatching {
    public var pat: Pattern!
    public var exp: Expression?
    public var rest: Expression?

    public init() {}
    public init(_ pat: Pattern, _ exp: Expression?, _ rest: Expression?) {
        self.pat = pat
        self.exp = exp
        self.rest = rest
    }
}

public class ForFlow : Flow {
    public var label: String?
    public var ini: ForInit?
    public var fin: Operation?

    public init(_ label: String?) {
        self.label = label
    }

    public func setCond(c: Expression) {
        pats = [PatternMatching(BooleanPattern(), c, nil)]
    }
}

public enum ForInit {
    case VariableDeclaration(Declaration)
    case InitOperation(Operation)
}

public class ForInFlow : Flow {
    public var label: String?

    public init(_ label: String?) {
        self.label = label
    }
}

public class WhileFlow : Flow {
    public var label: String?

    public init(_ label: String?) {
        self.label = label
    }
}

public class RepeatWhileFlow : Flow {
    public var label: String?

    public init(_ label: String?) {
        self.label = label
    }

    public func setCond(c: Expression) {
        pats = [PatternMatching(BooleanPattern(), c, nil)]
    }
}

public class IfFlow : Flow {
    public var label: String?
    public var els: ElseClause?

    public init(_ label: String?) {
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
    public var catches: [CatchFlow] = []
}

public class CatchFlow : Flow {}

public class FlowSwitch {
    public var label: String?
    public var cases: [CaseFlow] = []

    public init(_ label: String?) {
        self.label = label
    }
}

public class CaseFlow : Flow {}
