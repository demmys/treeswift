import AST

class ProcedureParser : GrammarParser {
    private var dp: DeclarationParser!
    private var pp: PatternParser!
    private var ep: ExpressionParser!
    private var ap: AttributesParser!

    func setParser(
        declarationParser dp: DeclarationParser,
        patternParser pp: PatternParser,
        expressionParser ep: ExpressionParser,
        attributesParser ap: AttributesParser
    ) {
        self.dp = dp
        self.pp = pp
        self.ep = ep
        self.ap = ap
    }

    func procedures() throws -> [Procedure] {
        var ps: [Procedure] = []
        while true {
            switch ts.look().kind {
            case .EndOfFile, .RightBrace, .Default, .Case:
                return ps
            default:
                ps.append(try procedure())
            }
        }
    }

    func procedure() throws -> Procedure {
        var x: Procedure!
        switch ts.match([
            .For, .While, .Repeat, .If, .Guard, .Defer, .Do, .Switch,
            .Break, .Continue, .Fallthrough, .Return, .Throw
        ]) {
        case .For:
            x = .FlowProcedure(try forFlow())
        case .While:
            x = .FlowProcedure(try whileFlow())
        case .Repeat:
            x = .FlowProcedure(try repeatWhileFlow())
        case .If:
            x = .FlowProcedure(try ifFlow())
        case .Guard:
            x = .FlowProcedure(try guardFlow())
        case .Defer:
            x = .FlowProcedure(try deferFlow())
        case .Do:
            x = .FlowProcedure(try doFlow())
        case .Switch:
            x = .FlowSwitchProcedure(try flowSwitch())
        case .Break:
            x = .OperationProcedure(breakOperation())
        case .Continue:
            x = .OperationProcedure(continueOperation())
        case .Fallthrough:
            x = .OperationProcedure(.FallthroughOperation)
        case .Return:
            x = .OperationProcedure(try returnOperation())
        case .Throw:
            x = .OperationProcedure(.ThrowOperation(try ep.expression()))
        case .Atmark, .Modifier, .Import, .Let, .Var, .Typealias, .Func, .Enum,
             .Indirect, .Struct, .Class, .Protocol, .Extension, .Prefix, .Infix,
             .Postfix:
            x = .DeclarationProcedure(try dp.declaration()) 
        case let .Identifier(s):
            // labeled-procedure, assignment-operation or expression-operation
            if case .Colon = ts.look(1).kind {
                ts.next(2)
                x = try labeledProcedure(s)
            }
            x = .OperationProcedure(try assignmentOrExpressionOperation())
        default:
            // assignment-operation or expression-operation
            x = .OperationProcedure(try assignmentOrExpressionOperation())
        }
        if !ts.test([.Semicolon, .LineFeed, .EndOfFile]) && ts.look().kind != .RightBrace {
            try ts.error(.ContinuousProcedure)
        }
        return x
    }

    private func forFlow(label: String? = nil) throws -> Flow {
        let (_, k) = find([.Semicolon, .In])
        guard case .Semicolon = k else {
            return try forInFlow()
        }
        ScopeManager.enterScope(.For)
        var parenthesized = false
        let x = ForFlow(label)
        if case .LeftParenthesis = ts.look().kind,
           let _ = findRightParenthesisBefore([.Semicolon], startIndex: 1) {
            parenthesized = true
        }
        if ts.test([.LeftParenthesis]) {
            parenthesized = true
        }
        // initializer
        x.ini = try forIni()
        if !ts.test([.Semicolon]) {
            try ts.error(.ExpectedSemicolonAfterForInit)
        }
        // condition
        if ts.look().kind != .Semicolon {
            x.setCond(try ep.expression())
        }
        if !ts.test([.Semicolon]) {
            try ts.error(.ExpectedSemicolonAfterForCondition)
        }
        // finalization
        switch ts.look().kind {
        case .RightParenthesis:
            if !parenthesized {
                try ts.error(.UnexpectedRightParenthesis)
                ts.next()
            }
        case .LeftBrace:
            if parenthesized {
                try ts.error(.ExpectedRightParenthesisAfterForSetting)
            }
        default:
            x.fin = try assignmentOrExpressionOperation()
        }
        if parenthesized {
            if !ts.test([.RightParenthesis]) {
                try ts.error(.ExpectedRightParenthesisAfterForSetting)
            }
        }
        // block
        x.block = try proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func forIni() throws -> ForInit? {
        switch ts.look().kind {
        case .Semicolon:
            return nil
        case .Atmark, .Modifier, .Class, .Var:
            let attrs = try ap.attributes()
            let (al, mods) = try disjointModifiers(try ap.declarationModifiers())
            if !ts.test([.Var]) {
                try ts.error(.ExpectedForVariableInit)
            }
            return .VariableDeclaration(try dp.variableDeclaration(attrs, al, mods))
        default:
            return .InitOperation(try assignmentOrExpressionOperation())
        }
    }

    private func forInFlow(label: String? = nil) throws -> ForInFlow {
        ScopeManager.enterScope(.ForIn)
        let x = ForInFlow(label)
        let p: Pattern
        if ts.test([.Case]) {
            p = try pp.conditionalPattern()
        } else {
            if ts.test([.Var]) {
                p = try pp.declarativePattern(.VariableCreation)
            } else {
                ts.test([.Let])
                p = try pp.declarativePattern(.ConstantCreation)
            }
        }
        if !ts.test([.In]) {
            try ts.error(.ExpectedInForForPattern)
        }
        let e = try ep.expression()
        if ts.test([.Where]) {
            x.pats = [PatternMatching(p, e, try ep.expression())]
        } else {
            x.pats = [PatternMatching(p, e, nil)]
        }
        x.block = try proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func whileFlow(label: String? = nil) throws -> WhileFlow {
        ScopeManager.enterScope(.While)
        let x = WhileFlow(label)
        x.pats = try patternMatchClause()
        x.block = try proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func repeatWhileFlow(label: String? = nil) throws -> RepeatWhileFlow {
        ScopeManager.enterScope(.RepeatWhile)
        let x = RepeatWhileFlow(label)
        x.block = try proceduresBlock()
        x.setCond(try ep.expression())
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func ifFlow(label: String? = nil) throws -> IfFlow {
        ScopeManager.enterScope(.If)
        let x = IfFlow(label)
        x.pats = try patternMatchClause()
        x.block = try proceduresBlock()
        if ts.test([.Else]) {
            if ts.test([.If]) {
                x.els = .ElseIf(try ifFlow())
            } else {
                x.els = .Else(try proceduresBlock())
            }
        }
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func guardFlow() throws -> GuardFlow {
        ScopeManager.enterScope(.Guard)
        let x = GuardFlow()
        x.pats = try patternMatchClause()
        if !ts.test([.Else]) {
            try ts.error(.ExpectedElseForGuard)
        }
        x.block = try proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func deferFlow() throws -> DeferFlow {
        ScopeManager.enterScope(.Defer)
        let x = DeferFlow()
        x.block = try proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func patternMatchClause() throws -> [PatternMatching] {
        var ps: [PatternMatching] = []
        switch ts.look().kind {
        case .RightBrace, .Else:
            throw ts.fatal(.ExpectedCondition)
        case .Let, .Var, .Case:
            repeat {
                ps.appendContentsOf(try matchingPattern())
            } while ts.test([.Comma])
        default:
            ps.append(PatternMatching(BooleanPattern(), try ep.expression(), nil))
            if ts.test([.Comma]) {
                repeat {
                    ps.appendContentsOf(try matchingPattern())
                } while ts.test([.Comma])
            }
        }
        return ps
    }

    private func matchingPattern() throws -> [PatternMatching] {
        switch ts.match([.Let, .Var, .Case]) {
        case .Let:
            return try optionalBindingBody(false)
        case .Var:
            return try optionalBindingBody(true)
        case .Case:
            let pm = PatternMatching()
            pm.pat = try pp.conditionalPattern()
            if !ts.test([.AssignmentOperator]) {
                try ts.error(.ExpectedEqualForPatternMatch)
            }
            pm.exp = try ep.expression()
            if ts.test([.Where]) {
                pm.rest = try ep.expression()
            }
            return [pm]
        default:
            throw ts.fatal(.ExpectedMatchingPattern)
        }
    }

    private func optionalBindingBody(isVariable: Bool) throws -> [PatternMatching] {
        var pms: [PatternMatching] = []
        repeat {
            let pm = PatternMatching()
            if isVariable {
                pm.pat = OptionalPattern(try pp.declarativePattern(.VariableCreation))
            } else {
                pm.pat = OptionalPattern(try pp.declarativePattern(.ConstantCreation))
            }
            if !ts.test([.AssignmentOperator]) {
                try ts.error(.ExpectedEqualForOptionalBinding)
            }
            pm.exp = try ep.expression()
            pms.append(pm)
        } while ts.test([.Comma])
        if ts.test([.Where]) {
            let e = try ep.expression()
            for pm in pms {
                pm.rest = e
            }
        }
        return pms
    }

    private func doFlow() throws -> DoFlow {
        ScopeManager.enterScope(.Do)
        let x = DoFlow()
        x.block = try proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        while ts.test([.Catch]) {
            ScopeManager.enterScope(.Catch)
            let c = CatchFlow()
            switch ts.match([.Where]) {
            case .Where:
                c.pats = [PatternMatching(IdentityPattern(), nil, try ep.expression())]
            case .LeftBrace:
                c.pats = [PatternMatching(IdentityPattern(), nil, nil)]
            default:
                let p = try pp.conditionalPattern()
                if ts.test([.Where]) {
                    c.pats = [PatternMatching(p, nil, try ep.expression())]
                } else {
                    c.pats = [PatternMatching(p, nil, nil)]
                }
            }
            c.block = try proceduresBlock()
            x.catches.append(c)
            c.associatedScope = try ScopeManager.leaveScope(ts.look())
        }
        return x
    }

    private func flowSwitch(label: String? = nil) throws -> FlowSwitch {
        let x = FlowSwitch(label)
        let cond = try ep.expression()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForFlowSwitch)
        }
        caseFlowsLoop: while true {
            switch ts.match([.Case, .Default]) {
            case .Case:
                x.cases.append(try caseFlow(cond))
            case .Default:
                x.cases.append(try defaultCaseFlow())
            default:
                break caseFlowsLoop
            }
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterFlowSwitch)
        }
        return x
    }

    private func caseFlow(cond: Expression) throws -> CaseFlow {
        ScopeManager.enterScope(.Case)
        let x = CaseFlow()
        x.pats = []
        repeat {
            let p = PatternMatching()
            p.pat = try pp.conditionalPattern()
            p.exp = cond
            if ts.test([.Where]) {
                p.rest = try ep.expression()
            }
            x.pats.append(p)
        } while ts.test([.Comma])
        if !ts.test([.Colon]) {
            try ts.error(.ExpectedColonAfterCasePattern)
        }
        x.block = try procedures()
        guard x.block.count > 0 else {
            throw ts.fatal(.EmptyCaseFlow)
        }
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func defaultCaseFlow() throws -> CaseFlow {
        ScopeManager.enterScope(.Case)
        if !ts.test([.Colon]) {
            try ts.error(.ExpectedColonAfterDefault)
        }
        let x = CaseFlow()
        x.pats = [PatternMatching(IdentityPattern(), nil, nil)]
        x.block = try procedures()
        guard x.block.count > 0 else {
            throw ts.fatal(.EmptyCaseFlow)
        }
        x.associatedScope = try ScopeManager.leaveScope(ts.look())
        return x
    }

    private func breakOperation() -> Operation {
        if case let .Identifier(s) = ts.look().kind {
            return .BreakOperation(s)
        }
        return .BreakOperation(nil)
    }

    private func continueOperation() -> Operation {
        if case let .Identifier(s) = ts.look().kind {
            return .ContinueOperation(s)
        }
        return .ContinueOperation(nil)
    }

    private func returnOperation() throws -> Operation {
        switch ts.look().kind {
        case .Semicolon, .LineFeed, .EndOfFile:
            return .ReturnOperation(ReturnValue(nil))
        default:
            return .ReturnOperation(ReturnValue(try ep.expression()))
        }
    }

    private func labeledProcedure(label: String) throws -> Procedure {
        switch ts.match([.For, .While, .Repeat, .If, .Switch]) {
        case .For:
            return .FlowProcedure(try forFlow(label))
        case .While:
            return .FlowProcedure(try whileFlow(label))
        case .Repeat:
            return .FlowProcedure(try repeatWhileFlow(label))
        case .If:
            return .FlowProcedure(try ifFlow(label))
        case .Switch:
            return .FlowSwitchProcedure(try flowSwitch(label))
        default:
            throw ts.fatal(.LabelWithUnexpectedFlow)
        }
    }

    private func assignmentOrExpressionOperation() throws -> Operation {
        let (_, k) = find([.AssignmentOperator, .Semicolon, .LineFeed], startIndex: 1)
        switch k {
        case .AssignmentOperator:
            let p = try pp.declarativePattern(.VariableReference)
            if !ts.test([.AssignmentOperator]) {
                try ts.error(.ExpectedEqualForAssignment)
            }
            return .AssignmentOperation(p, try ep.expression())
        default:
            return .ExpressionOperation(try ep.expression())
        }
    }

    func proceduresBlock() throws -> [Procedure] {
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForProceduresBlock)
        }
        let ps = try procedures()
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterProceduresBlock)
        }
        return ps
    }
}
