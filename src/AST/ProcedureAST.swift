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
    public var type: Type?
    let value: Expression?

    public init(_ v: Expression?) {
        value = v
    }
}

public class Flow : ScopeTrackable, CustomStringConvertible {
    public var pats: [PatternMatching]!
    public var block: [Procedure]!
    public var associatedScope: Scope!

    public init() {}

    public var scope: Scope { return associatedScope }
    public var description: String { return "<<error: no description provided>>" }
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

    public override var description: String { get {
        return "(ForFlow label: \(label) \(ini) \(pats) \(fin) \(block))"
    } }
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

    public override var description: String { get {
        return "(ForInFlow label: \(label) \(pats) \(block))"
    } }
}

public class WhileFlow : Flow {
    public var label: String?

    public init(_ label: String?) {
        self.label = label
    }

    public override var description: String { get {
        return "(WhileFlow label: \(label) \(pats) \(block))"
    } }
}

public class RepeatWhileFlow : Flow {
    public var label: String?

    public init(_ label: String?) {
        self.label = label
    }

    public func setCond(c: Expression) {
        pats = [PatternMatching(BooleanPattern(), c, nil)]
    }

    public override var description: String { get {
        return "(RepeatWhileFlow label: \(label) \(pats) \(block))"
    } }
}

public class IfFlow : Flow {
    public var label: String?
    public var els: ElseClause?

    public init(_ label: String?) {
        self.label = label
    }

    public override var description: String { get {
        return "(IfFlow label: \(label) \(pats) \(block) \(els))"
    } }
}

public enum ElseClause {
    case Else([Procedure])
    case ElseIf(IfFlow)
}

public class GuardFlow : Flow {
    public override var description: String { get {
        return "(GuardFlow \(pats) \(block))"
    } }
}

public class DeferFlow : Flow {
    public override var description: String { get {
        return "(DeferFlow \(block))"
    } }
}

public class DoFlow : Flow {
    public var catches: [CatchFlow] = []

    public override var description: String { get {
        return "(DoFlow \(block) \(catches))"
    } }
}

public class CatchFlow : Flow {
    public override var description: String { get {
        return "(CatchFlow \(pats) \(block))"
    } }
}

public class FlowSwitch {
    public var label: String?
    public var cases: [CaseFlow] = []

    public init(_ label: String?) {
        self.label = label
    }
}

public class CaseFlow : Flow {
    public override var description: String { get {
        return "(CaseFlow \(pats) \(block))"
    } }
}
