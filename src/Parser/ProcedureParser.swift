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
            // labeled-procedure or expression-operation
            if case .Colon = ts.look(1).kind {
                ts.next(2)
                x = try labeledProcedure(s)
            }
            x = .OperationProcedure(.ExpressionOperation(try ep.expression()))
        default:
            // assignment-operation or expression-operation
            x = .OperationProcedure(try assignmentOrExpressionOperation())
        }
        guard ts.test([.Semicolon, .LineFeed, .EndOfFile]) else {
            throw ParserError.Error("Continuous procedure must be separated by ';'", ts.look().info)
        }
        return x
    }

    private func forFlow(label: String? = nil) throws -> Flow {
        let (_, k) = find([.Semicolon, .In])
        guard case .Semicolon = k else {
            return try forInFlow()
        }
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
        guard ts.test([.Semicolon]) else {
            throw ParserError.Error("Expected ';' after initialize statement of ForFlow", ts.look().info)
        }
        // condition
        if ts.look().kind != .Semicolon {
            x.setCond(try ep.expression())
        }
        guard ts.test([.Semicolon]) else {
            throw ParserError.Error("Expected ';' after condition of ForFlow", ts.look().info)
        }
        // finalization
        switch ts.look().kind {
        case .RightParenthesis:
            if !parenthesized {
                throw ParserError.Error("Expected '{' after setting of ForFlow", ts.look().info)
            }
        case .LeftBrace:
            if parenthesized {
                throw ParserError.Error("Expected ')' after setting of parenthesized ForFlow", ts.look().info)
            }
        default:
            x.fin = try assignmentOrExpressionOperation()
        }
        if parenthesized {
            guard ts.test([.RightParenthesis]) else {
                throw ParserError.Error("Expected ')' after ForFlow with parenthesis", ts.look().info)
            }
        }
        // block
        x.block = try proceduresBlock()
        return x
    }

    private func forIni() throws -> ForInit? {
        switch ts.look().kind {
        case .Semicolon:
            return nil
        case .Atmark, .Modifier, .Class, .Var:
            let attrs = try ap.attributes()
            let mods = try ap.declarationModifiers()
            guard ts.test([.Var]) else {
                throw ParserError.Error("Expected 'var' for the declaration in initialize condition.", ts.look().info)
            }
            return .VariableDeclaration(try dp.variableDeclaration(attrs, mods))
        default:
            return .InitOperation(try assignmentOrExpressionOperation())
        }
    }

    private func forInFlow(label: String? = nil) throws -> ForInFlow {
        let x = ForInFlow(label)
        var p: Pattern!
        if ts.test([.Case]) {
            p = try pp.conditionalPattern()
        } else {
            p = try pp.declarationalPattern()
        }
        guard ts.test([.In]) else {
            throw ParserError.Error("Expected 'in' after pattern of ForInFlow", ts.look().info)
        }
        let e = try ep.expression()
        if ts.test([.Where]) {
            x.pats = [PatternMatching(p, e, try ep.expression())]
        } else {
            x.pats = [PatternMatching(p, e, nil)]
        }
        x.block = try proceduresBlock()
        return x
    }

    private func whileFlow(label: String? = nil) throws -> WhileFlow {
        let x = WhileFlow(label)
        x.pats = try patternMatchClause()
        x.block = try proceduresBlock()
        return x
    }

    private func repeatWhileFlow(label: String? = nil) throws -> RepeatWhileFlow {
        let x = RepeatWhileFlow(label)
        x.block = try proceduresBlock()
        x.setCond(try ep.expression())
        return x
    }

    private func ifFlow(label: String? = nil) throws -> IfFlow {
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
        return x
    }

    private func guardFlow() throws -> GuardFlow {
        let x = GuardFlow()
        x.pats = try patternMatchClause()
        guard ts.test([.Else]) else {
            throw ParserError.Error("Expected 'else' after condition of GuardFlow", ts.look().info)
        }
        x.block = try proceduresBlock()
        return x
    }

    private func deferFlow() throws -> DeferFlow {
        let x = DeferFlow()
        x.block = try proceduresBlock()
        return x
    }

    private func patternMatchClause() throws -> [PatternMatching] {
        var ps: [PatternMatching] = []
        switch ts.look().kind {
        case .RightBrace, .Else:
            throw ParserError.Error("Expected condition of the flow", ts.look().info)
        case .Let, .Var, .Case:
            repeat {
                ps.appendContentsOf(try matchingPattern())
            } while ts.test([.Comma])
        default:
            ps.append(PatternMatching(.BooleanPattern, try ep.expression(), nil))
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
            return try optionalBindingBody({ .OptionalBindingConstantPattern($0) })
        case .Var:
            return try optionalBindingBody({ .OptionalBindingVariablePattern($0) })
        case .Case:
            let pm = PatternMatching()
            pm.pat = try pp.conditionalPattern()
            guard ts.test([.AssignmentOperator]) else {
                throw ParserError.Error("Expected '=' for the case pattern of pattern matching clause", ts.look().info)
            }
            pm.exp = try ep.expression()
            if ts.test([.Where]) {
                pm.rest = try ep.expression()
            }
            return [pm]
        default:
            throw ParserError.Error("Expected matching pattern.", ts.look().info)
        }
    }

    private func optionalBindingBody(wrap: Pattern -> Pattern) throws -> [PatternMatching] {
        var pms: [PatternMatching] = []
        repeat {
            let pm = PatternMatching()
            pm.pat = wrap(try pp.declarationalPattern())
            guard ts.test([.AssignmentOperator]) else {
                throw ParserError.Error("Expected '=' after the pattern of optional binding pattern", ts.look().info)
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
        let x = DoFlow()
        x.block = try proceduresBlock()
        while ts.test([.Catch]) {
            let c = CatchFlow()
            switch ts.match([.Where]) {
            case .Where:
                c.pats = [PatternMatching(.IdentityPattern, nil, try ep.expression())]
            case .LeftBrace:
                c.pats = [PatternMatching(.IdentityPattern, nil, nil)]
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
        }
        return x
    }

    private func flowSwitch(label: String? = nil) throws -> FlowSwitch {
        let x = FlowSwitch(label)
        let cond = try ep.expression()
        guard ts.test([.LeftBrace]) else {
            throw ParserError.Error("Expected '{' after switch condition.", ts.look().info)
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
        guard ts.test([.RightBrace]) else {
            throw ParserError.Error("Expected '}' at the end of flow switch.", ts.look().info)
        }
        return x
    }

    private func caseFlow(cond: Expression) throws -> CaseFlow {
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
        guard ts.test([.Colon]) else {
            throw ParserError.Error("Expected ':' after patterns of case flow.", ts.look().info)
        }
        x.block = try procedures()
        guard x.block.count > 0 else {
            throw ParserError.Error("Case flow should have at least one procedure.", ts.look().info)
        }
        return x
    }

    private func defaultCaseFlow() throws -> CaseFlow {
        guard ts.test([.Colon]) else {
            throw ParserError.Error("Expected ':' after 'default' in flow switch.", ts.look().info)
        }
        let x = CaseFlow()
        x.pats = [PatternMatching(.IdentityPattern, nil, nil)]
        x.block = try procedures()
        guard x.block.count > 0 else {
            throw ParserError.Error("Case flow should have at least one procedure.", ts.look().info)
        }
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
            return .ReturnOperation(nil)
        default:
            return .ReturnOperation(try ep.expression())
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
            throw ParserError.Error("Only loop flows, if flow, and flow switch can have a label", ts.look().info)
        }
    }

    private func assignmentOrExpressionOperation() throws -> Operation {
        let (_, k) = find([.AssignmentOperator, .Semicolon, .LineFeed])
        switch k {
        case .AssignmentOperator:
            let p = try pp.declarationalPattern()
            guard ts.test([.AssignmentOperator]) else {
                throw ParserError.Error("Expected '=' after pattern in the assignment operation.", ts.look().info)
            }
            return .AssignmentOperation(p, try ep.expression())
        default:
            return .ExpressionOperation(try ep.expression())
        }
    }

    func proceduresBlock() throws -> [Procedure] {
        guard ts.test([.LeftBrace]) else {
            throw ParserError.Error("Expected '{' before procedures block", ts.look().info)
        }
        let ps = try procedures()
        guard ts.test([.RightBrace]) else {
            throw ParserError.Error("Expected '}' after procedures block", ts.look().info)
        }
        return ps
    }
}
