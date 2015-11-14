import AST

extension TypeInference {
    public func visit(node: FlowSwitch) throws {
        assert(false, "Flow switch is not implemented.")
    }

    public func visit(node: ForFlow) throws {
        assert(false, "For flow is not implemented.")
    }

    public func visit(node: ForInFlow) throws {
        assert(false, "For in flow is not implemented.")
    }

    public func visit(node: WhileFlow) throws {
        assert(false, "While flow is not implemented.")
    }

    public func visit(node: RepeatWhileFlow) throws {
        assert(false, "Repeat while flow is not implemented.")
    }

    public func visit(node: IfFlow) throws {
        try visitFlow(node)
        if let els = node.els {
            switch els {
            case let .Else(ps):
                for p in ps {
                    try p.accept(self)
                }
            case let .ElseIf(f):
                try f.accept(self)
            }
        }
    }

    public func visit(node: GuardFlow) throws {
        assert(false, "Guard flow is not implemented.")
    }

    public func visit(node: DeferFlow) throws {
        assert(false, "Defer flow is not implemented.")
    }

    public func visit(node: DoFlow) throws {
        assert(false, "Do flow is not implemented.")
    }

    public func visit(node: CatchFlow) throws {
        assert(false, "Catch flow is not implemented.")
    }

    public func visit(node: CaseFlow) throws {
        assert(false, "Case flow is not implemented.")
    }

    private func visitFlow(node: Flow) throws {
        for p in node.pats {
            if let e = p.exp {
                addConstraint(p.pat, e)
                try e.accept(self)
            }
            if let e = p.rest {
                try e.accept(self)
            }
            try p.pat.accept(self)
        }
        for p in node.block {
            try p.accept(self)
        }
    }

    public func visit(node: Operation) throws {
        switch node {
        case let .ExpressionOperation(e):
            try e.accept(self)
        case let .AssignmentOperation(p, e):
            addConstraint(p, e)
            try p.accept(self)
            try e.accept(self)
        case let .ReturnOperation(v):
            if let e = v.exp {
                addConstraint(v, e)
                try e.accept(self)
            }
        case .ThrowOperation:
            assert(false, "Error handling is not implemented")
        default:
            break
        }
    }
}
