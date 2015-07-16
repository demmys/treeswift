class StatementParser {
    private let ts: TokenStream
    private let pu: ParserUtil
    private let ep: ExpressionParser
    private let dp: DeclarationParser

    init(_ ts: TokenStream) {
        self.ts = ts
        pu = ParserUtil(ts)
        ep = ExpressionParser(ts)
        dp = DeclarationParser(ts)
    }

    func statement() throws -> Statement {
        var s: Statement!
        switch ts.look().kind {
        // loop-statement or branch-statement
        case .For, .While, .Repeat, .If, .Guard, .Switch:
            s = try controlStatement()
        case let .Identifier(k):
            switch ts.look(1).kind {
            // labeled-statement
            case .Colon:
                switch k {
                case .ImplicitParameter:
                    throw ParserError.Error("Implicit parameter can't be a label of frow control statement.", ts.look().info)
                default:
                    ts.next(2)
                    let b = ControlStatementBuilder()
                    b.label = k
                    s = try controlStatement(b)
                }
            // expression
            default:
                s = try ep.expression()
            }
        // control-transfer-statement
        case .Break:
            ts.next()
            s = try breakStatement()
        case .Continue:
            ts.next()
            s = try continueStatement()
        case .Fallthrough:
            ts.next()
            s = .Fallthrough
        case .Return:
            ts.next()
            s = try returnStatement()
        case .Throw:
            ts.next()
            s = try throwStatement()
        // defer-statement
        case .Defer:
            ts.next()
            s = try deferStatement()
        // do-statement
        case .Do:
            ts.next()
            s = try doStatement()
        // declaration
        case .Import, .Let, .Var, .Typealias, .Func, .Enum,
             .Struct, .Class, .Protocol, .Init, .Deinit, .Extension,
             .Subscript, .Prefix, .Postfix, .Infix:
            s = .Declaration(try dp.declaration())
        // declaration (with attributes)
        case .Attribute:
            let b = DeclarationBuilder()
            b.attrs = dp.attributes()
            b.mods = dp.modifiers()
            s = .Declaration(try dp.declaration(b))
        // declaration (with declaration-modifiers or access-level-modifier)
        case var .Modifier(k):
            let b = DeclarationBuilder()
            b.mods = modifiers()
            s = try .Declaration(dp.declaration(b))
        // expression
        case .Try:
            // TODO
        case .PrefixOperator:
            // TODO
        case .PrefixAmpersand:
            // TODO
        default:
            // TODO
        }
        guard isTerminalToken() else {
            throw ParserError.Error("Continuous statement should be separated by ';'", ts.look().info)
        }
        ts.next(1, skipLineFeed: false)
        return s
    }

    private func isTerminalToken() -> Bool {
        switch ts.look(0, skipLineFeed: false).kind {
        case .LineFeed, .Semicolon, .EndOfFile:
            return true
        default:
            return false
        }
    }

    private func controlStatement(
        b: ControlStatementBuilder = ControlStatementBuilder()
    ) throws -> Statement {
        switch ts.look().kind {
        // loop-statement
        case .For:
            ts.next()
            let (_, k) = pu.find([.In, .Semicolon])
            if k == .In {
                return try forInStatement(b)
            } else {
                return try forStatement(b)
            }
        case .While:
            ts.next()
            return try whileStatement(b)
        case .Repeat:
            ts.next()
            return try repeatWhileStatement(b)
        // branch-statement
        case .If:
            ts.next()
            return try ifStatement(b)
        case .Guard:
            ts.next()
            return try guardStatement(b)
        case .Switch:
            ts.next()
            return try switchStatement(b)
        }
    }

    /*
     * for-statement
     */
    private func forStatement(b: ControlStatementBuilder) throws -> Statement {
        var parenthesized = false
        let c = ForStatementCondition()
        if ts.look().kind == .LeftParenthesis {
            parenthesized = true
            ts.next()
        }
        try forInit(c)
        try forConfirmation(c)
        try forFinalize(c, parenthesized: parenthesized)
        b.cond = .For(c)
        b.body = try dp.codeBlock()
        return b.build()
    }

    private func forInit(c: ForStatementCondition) throws {
        switch ts.look().kind {
        case .Semicolon:
            break
        case .Attribute:
            let b = DeclarationBuilder()
            b.attrs = dp.attributes()
            b.mods = dp.modifiers()
            c.pre = .Declaration(try dp.variableDeclaration(b))
        case .Modifier:
            let b = DeclarationBuilder()
            b.mods = dp.modifiers()
            c.pre = .Declaration(try dp.variableDeclaration(b))
        case .Var:
            c.pre = .Declaration(try dp.variableDeclaration())
        default:
            c.pre = .Expressions(try ep.expressionList())
        }
        guard ts.look().kind == .Semicolon else {
            throw ParserError.Error("Expected semicolon after the initialize part of for statement", ts.look().info)
        }
        ts.next()
    }

    private func forConfirmation(c: ForStatementCondition) throws {
        if ts.look().kind != .Semicolon {
            c.cond = try ep.expressionList()
            guard ts.look().kind == .Semicolon else {
                throw ParserError.Error("Expected semicolon after the condition part of for statement", ts.look().info)
            }
        }
        ts.next()
    }

    private func forFinalize(c: ForStatementCondition, parenthesized: Bool) throws {
        if parenthesized {
            if ts.look().kind != .RightParenthesis {
                c.post = try ep.expressionList()
            }
            guard ts.look().kind == .RightParenthesis else {
                throw ParserError.Error("Expected code block after for condition", ts.look().info)
            }
        } else if ts.look().kind != .LeftBrace {
            c.post = try ep.expressionList()
        }
    }

    /*
     * for-in-statement
     */
    private func forInStatement(b: ControlStatementBuilder) throws -> Statement {
        let c = ForInStatementCondition()
        if ts.look().kind == .Case {
            ts.next()
            c.pat = .switchCase(try pp.pattern())
        } else {
            c.pat = .normal(try pp.pattern())
        }
        guard ts.look().kind == .In else {
            throw ParserError.Error("Illigal pattern.", ts.look().info)
        }
        ts.next()
        c.src = try ep.expression()
        c.filter = try whereClause()
        b.cond = .ForIn(c)
        b.body = try dp.codeBlock()
        return b.build()
    }

    /*
     * while-statement
     */
     private func whileStatement(b: ControlStatementBuilder) throws -> Statement {
         let (e, cs) = try conditionClause()
         b.cond = .While(e, cs)
         b.body = try dp.codeBlock()
         return b.build()
     }

    /*
     * repeat-while-statement
     */
    private func repeatWhileStatement(b: ControlStatementBuilder) throws -> Statement {
        b.body = try dp.codeBlock()
        guard ts.look().kind == .While else {
            throw ParserError.Error("Expected 'while' after a body of repeat while statement", ts.look().info)
        }
        b.cond = .RepeatWhile(try ep.expression())
        return b.build()
    }

    /*
     * if-statement
     */
    private func ifStatement(b: ControlStatementBuilder) throws -> Statement {
        let c = IfStatementCondition()
        (c.condExp, c.conds) = try conditionClause()
        b.body = try dp.codeBlock()
        if ts.look().kind == .Else {
            ts.next()
            switch ts.look().kind {
            case .LeftBrace:
                c.els = .CodeBlock(try dp.codeBlock())
            case .If:
                ts.next()
                c.els = .IfStatement(try ifStatement(ControlStatementBuilder()))
            }
        }
        b.cond = .If(c)
        return b.build()
    }

    /*
     * guard-statement
     */
    private func guardStatement(b: ControlStatementBuilder) throws -> Statement {
        let (e, cs) = try conditionClause()
        b.cond = .Guard(e, cs)
        guard ts.look().kind == .Else else {
            throw ParserError.Error("Expected 'else' after a condition of guard statement", ts.look().kind.info)
        }
        ts.next()
        b.body = try dp.codeBlock()
        return b.build()
    }

    /*
     * switch-statement
     */
    private func switchStatement(b: ControlStatementBuilder) throws -> Statement {
        let c = SwitchStatementCondition()
        c.cond = try ep.expression()
        guard ts.look().kind == .LeftBrace else {
            throw ParserError.Error("Expected brace surrounded body of switch statement", ts.look().info)
        }
        ts.next()
        c.cases = []
        while ts.look().kind == .Case {
            var sc = SwitchStatementCondition.SwitchCase()
            // case-label
            var cis: [SwitchStatementCondition.CaseItem] = []
            repeat {
                ts.next()
                cis.append(try switchCaseItem())
            } while ts.look().kind == .Comma
            cs.label = cis
            guard ts.look().kind == .Colon else {
                throw ParserError.Error("Expected colon after switch case item list", ts.look().info)
            }
            // statements
            sc.body = try switchCaseStatements()
            c.cases.append(sc)
        }
        if ts.look().kind == .Default {
            var sc: SwitchStatementCondition.SwitchCase()
            sc.body = try switchCaseStatements()
            c.cases.append(sc)
        }
        guard c.cases.count > 0 else {
            throw ParserError.Error("Switch statement must have at least one case", ts.look().info)
        }
        guard ts.look().kind == .RightBrace else {
            throw ParserError.Error("Expected closing brace after a statement body", ts.look().info)
        }
        ts.next()
    }

    private func switchCaseItem() throws -> SwitchStatementCondition.CaseItem {
        let i = SwitchStatementCondition.CaseItem()
        i.pat = try pp.pattern()
        i.filter = try whereClause()
        return i
    }

    private func switchCaseStatements() throws -> [Statement]? {
        switch ts.look().kind {
        case .Semicolon:
            return nil
        case .Case, .Default, .RightBrace:
            throw ParserError.Error("Case of switch statement must have at least one statement. If you want to indicate that there is no statement to execute, just put ';'.", ts.look().info)
        default:
            var ss: [Statements] = []
            statementsLoop: while {
                ss.append(try statement())
                switch ts.look().kind {
                case .Case, .Default, .RightBrace:
                    break statementsLoop
                default:
                    break
                }
            }
            return ss
        }
    }

    /*
     * control-transfer-statement
     */
    private func breakStatement() throws -> Statement {
        switch ts.look().kind {
        case let .Identifier(k):
            ts.next()
            return .Break(k)
        default:
            return .Break(nil)
        }
    }

    private func continueStatement() throws -> Statement {
        switch ts.look().kind {
        case let .Identifier(k):
            ts.next()
            return .Continue(k)
        default:
            return .Continue(nil)
        }
    }

    private func returnStatement() throws -> Statement {
        if isTerminalToken() {
            return .Return(nil)
        }
        return .Return(try ep.expression())
    }

    private func throwStatement() throws -> Statement {
        if isTerminalToken() {
            return .Throw(nil)
        }
        return .Throw(try ep.expression())
    }

    /*
     * defer-statement
     */
    private func deferStatement() throws -> Statement {
        return .Defer(try dp.codeBlock())
    }

    /*
     * do-statement
     */
    private func doStatement() throws -> Statement {
        let c = DoStatementCondition()
        c.body = try dp.codeBlock()
        var ccs: [DoStatementCondition.CatchClause] = []
        while ts.look().kind == .Catch {
            ts.next()
            var cc = DoStatementCondition.CatchClause()
            switch ts.look().kind {
            case .Where:
                cc.filter = try whereClause()
            case .LeftBrace:
                break
            default:
                cc.pat = try pp.pattern()
                cc.filter = try pp.pattern()
            }
            cc.body = try dp.codeBlock()
            ccs.append(cc)
        }
        if ccs.count > 0 {
            c.catches = ccs
        }
        return c.build()
    }

    /*
     * condition-clause
     */
    private func conditionClause() throws -> (Expression?, [Condition]?) {
        switch ts.look().kind {
        case .Case, .Let, .Var:
            return (nil, try conditionList())
        default:
            let e = try expression()
            if ts.look().kind == .Comma {
                ts.next()
                return (e, try conditionList())
            }
            return (e, nil)
        }
    }

    private func conditionList() throws -> [Condition] {
        var cs: [Condition] = []
        conditionLoop: while true {
            switch ts.look().kind {
            case .Case:
                cs.append(try caseCondition())
            case .Let, .Var:
                cs.append(try optionalCondition())
            default:
                break conditionLoop
            }
        }
        return cs
    }

    private func caseCondition() throws -> Condition {
        ts.next()
        let b = CaseConditionBuilder()
        b.pat = try pp.pattern()
        guard ts.look().kind == .AssignmentOperator else {
            throw ParserError.Error("Expected assignment operator after pattern in case pattern.", ts.look().info)
        }
        ts.next()
        b.exp = try expression()
        b.filter = try whereClause()
        return b.build()
    }
    
    private func optionalCondition() throws -> Condition {
        let b = OptionalConditionBuilder()
        switch ts.look().kind {
        case .Let:
            b.binds.append(optionalBinding(.Let))
        case .Var:
            b.binds.append(optionalBinding(.Var))
        default:
            b.binds.append(optionalBinding())
        }
        return b.build()
    }

    private func optionalBinding(type: Condition.BindingType? = nil) throw -> OptionalBinding {
        let ob = OptionalConditionBuilder.OptionalBinding()
        ob.type = type
        ob.pat = try pp.pattern()
        guard ts.look().kind == .AssignmentOperator else {
            throw ParserError.Error("Expected assignment operator after pattern of binding pattern.", ts.look().info)
        }
        ts.next()
        ob.exp = try ep.pattern()
        return ob.build()
    }

    private func whereClause() throws -> Expression? {
        guard ts.look().kind == .Where else {
            return nil
        }
        ts.next()
        return try expression()
    }
}
