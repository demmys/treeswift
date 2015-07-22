class ProcedureParser : GrammarParser {
    // private var dp: DeclarationParser!
    private var pp: PatternParser!
    private var ep: ExpressionParser!

    func setParser(
        // declarationParser dp: DeclarationParser,
        patternParser pp: PatternParser,
        expressionParser ep: ExpressionParser
    ) {
        // self.dp = dp
        self.pp = pp
        self.ep = ep
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
        case .Atmark:
            // declaration beggining with attributes
            // TODO
            throw ParserError.Error("Declarations are not implemented yet", ts.look().info)
        case .Modifier:
            // declaration beggining with modifiers
            // TODO
            throw ParserError.Error("Declarations are not implemented yet", ts.look().info)
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
        case .Import, .Let, .Var, .Typealias, .Func, .Enum, .Indirect, .Struct,
             .Class, .Protocol, .Extension, .Prefix, .Infix, .Postfix:
            // TODO
            // x = .DeclarationProcedure(try dp.declaration()) 
            throw ParserError.Error("Declarations are not implemented yet", ts.look().info)
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

    func forFlow(label: String? = nil) throws -> Flow {
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

    func forIni() throws -> ForInit? {
        switch ts.look().kind {
        case .Semicolon:
            return nil
        case .Atmark:
            // TODO
            throw ParserError.Error("Declarations are not implemented yet", ts.look().info)
        case .Modifier:
            // TODO
            throw ParserError.Error("Declarations are not implemented yet", ts.look().info)
        case .Var:
            // TODO
            // return .VariableDeclaration(try dp.variableDeclaration())
            throw ParserError.Error("Declarations are not implemented yet", ts.look().info)
        default:
            return .InitOperation(try assignmentOrExpressionOperation())
        }
    }

    func forInFlow(label: String? = nil) throws -> ForInFlow {
        let x = ForInFlow(label)
        var p: Pattern!
        if ts.test([.Case]) {
            p = try pp.declarationalPattern()
        } else {
            p = try pp.conditionalPattern()
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

    func whileFlow(label: String? = nil) throws -> WhileFlow {
        let x = WhileFlow(label)
        x.pats = try patternMatchClause()
        x.block = try proceduresBlock()
        return x
    }

    func repeatWhileFlow(label: String? = nil) throws -> RepeatWhileFlow {
        let x = RepeatWhileFlow(label)
        x.block = try proceduresBlock()
        x.setCond(try ep.expression())
        return x
    }

    func ifFlow(label: String? = nil) throws -> IfFlow {
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

    func guardFlow() throws -> GuardFlow {
        let x = GuardFlow()
        x.pats = try patternMatchClause()
        guard ts.test([.Else]) else {
            throw ParserError.Error("Expected 'else' after condition of GuardFlow", ts.look().info)
        }
        x.block = try proceduresBlock()
        return x
    }

    func deferFlow() throws -> DeferFlow {
        let x = DeferFlow()
        x.block = try proceduresBlock()
        return x
    }

    func patternMatchClause() throws -> [PatternMatching] {
        var ps: [PatternMatching] = []
        switch ts.look().kind {
        case .RightBrace, .Else:
            throw ParserError.Error("Expected condition of the flow", ts.look().info)
        case .Let, .Var, .Case:
            repeat {
                ps.extend(try matchingPattern())
            } while ts.test([.Comma])
        default:
            ps.append(PatternMatching(.BooleanPattern, try ep.expression(), nil))
            if ts.test([.Comma]) {
                repeat {
                    ps.extend(try matchingPattern())
                } while ts.test([.Comma])
            }
        }
        return ps
    }

    func matchingPattern() throws -> [PatternMatching] {
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

    func optionalBindingBody(wrap: Pattern -> Pattern) throws -> [PatternMatching] {
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

    func doFlow() throws -> DoFlow {
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

    func flowSwitch(label: String? = nil) throws -> FlowSwitch {
        // let x = FlowSwitch(label)
        throw ParserError.Error("FlowSwitch is not implemented yet.", ts.look().info)
    }

    func breakOperation() -> Operation {
        if case let .Identifier(s) = ts.look().kind {
            return .BreakOperation(s)
        }
        return .BreakOperation(nil)
    }

    func continueOperation() -> Operation {
        if case let .Identifier(s) = ts.look().kind {
            return .ContinueOperation(s)
        }
        return .ContinueOperation(nil)
    }

    func returnOperation() throws -> Operation {
        switch ts.look().kind {
        case .Semicolon, .LineFeed, .EndOfFile:
            return .ReturnOperation(nil)
        default:
            return .ReturnOperation(try ep.expression())
        }
    }

    func labeledProcedure(label: String) throws -> Procedure {
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

    func assignmentOrExpressionOperation() throws -> Operation {
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
