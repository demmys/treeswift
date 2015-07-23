public enum Procedure {
    case DeclarationProcedure(Declaration)
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

public class Flow : CustomStringConvertible {
    var pats: [PatternMatching]!
    var block: [Procedure]!

    public var description: String { get {
        return "<<error: no description provided>>"
    } }
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

    public override var description: String { get {
        return "(ForFlow label: \(label) \(ini) \(pats) \(fin) \(block))"
    } }
}

public enum ForInit {
    case VariableDeclaration(Declaration)
    case InitOperation(Operation)
}

public class ForInFlow : Flow {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }

    public override var description: String { get {
        return "(ForInFlow label: \(label) \(pats) \(block))"
    } }
}

public class WhileFlow : Flow {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }

    public override var description: String { get {
        return "(WhileFlow label: \(label) \(pats) \(block))"
    } }
}

public class RepeatWhileFlow : Flow {
    var label: String?

    init(_ label: String?) {
        self.label = label
    }

    func setCond(c: Expression) {
        pats = [PatternMatching(.BooleanPattern, c, nil)]
    }

    public override var description: String { get {
        return "(RepeatWhileFlow label: \(label) \(pats) \(block))"
    } }
}

public class IfFlow : Flow {
    var label: String?
    var els: ElseClause?

    init(_ label: String?) {
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
    var catches: [CatchFlow] = []

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
    var label: String?

    init(_ label: String?) {
        self.label = label
    }
}

public class CaseFlow : Flow {}
