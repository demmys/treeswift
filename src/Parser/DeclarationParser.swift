import AST

class DeclarationParser : GrammarParser {
    private var prp: ProcedureParser!
    private var ptp: PatternParser!
    private var ep: ExpressionParser!
    private var tp: TypeParser!
    private var ap: AttributesParser!
    private var gp: GenericsParser!

    func setParser(
        procedureParser prp: ProcedureParser!,
        patternParser ptp: PatternParser,
        expressionParser ep: ExpressionParser,
        typeParser tp: TypeParser,
        attributesParser ap: AttributesParser,
        genericsParser gp: GenericsParser
    ) {
        self.prp = prp
        self.ptp = ptp
        self.ep = ep
        self.tp = tp
        self.ap = ap
        self.gp = gp
    }

    func topLevelDeclaration(fileName: String) throws -> TopLevelDeclaration {
        ScopeManager.enterScope(.File)
        ScopeManager.setFileName(fileName)
        return TopLevelDeclaration(
            procedures: try prp.procedures(),
            fileScope: try ScopeManager.leaveScope(.File, nil)
        )
    }

    func moduleDeclarations() throws -> [Declaration] {
        var xs: [Declaration] = []
        declarationLoop: while true {
            switch ts.look().kind {
            case .RightBrace, .EndOfFile:
                break declarationLoop
            default:
                xs.append(try moduleDeclaration())
            }
        }
        return xs
    }

    func moduleDeclaration(parsedAttrs: [Attribute]? = nil) throws -> Declaration {
        var attrs = try ap.attributes()
        if let pa = parsedAttrs {
            attrs = pa
        }
        let (al, mods) = try disjointModifiers(try ap.declarationModifiers())
        let trackable = ts.look()
        switch ts.match([
            .Import, .Let, .Var, .Typealias, .Func, .Indirect, .Enum,
            .Struct, .Class, .Protocol, .Init, .Extension, .Subscript,
            .Prefix, .Postfix, .Infix
        ]) {
        case .Import:
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeImport)
            }
            return try importDeclaration(attrs, trackable)
        case .Let:
            return try moduleConstantDeclaration(attrs, al, mods)
        case .Var:
            return try moduleVariableDeclaration(attrs, al, mods)
        case .Typealias:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeTypealias)
            }
            return try associatedTypeDeclaration(attrs, al)
        case .Func:
            return try functionDeclaration(attrs, al, mods, forModule: true)
        case .Indirect:
            if !ts.test([.Enum]) {
                try ts.error(.ExpectedEnum)
            }
            if mods.count > 0 {
                try ts.error(.ModifierBeforeEnum)
            }
            return try enumDeclaration(attrs, al, isIndirect: true, forModule: true)
        case .Enum:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeEnum)
            }
            return try enumDeclaration(attrs, al, forModule: true)
        case .Struct:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeStruct)
            }
            return try structDeclaration(attrs, al, forModule: true)
        case .Class:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeClass)
            }
            return try classDeclaration(attrs, al, forModule: true)
        case .Protocol:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeProtocol)
            }
            return try protocolDeclaration(attrs, al)
        case .Init:
            return try initializerDeclaration(attrs, al, mods, forModule: true)
        case .Extension:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeExtension)
            }
            if mods.count > 0 {
                try ts.error(.ModifierBeforeExtension)
            }
            return try extensionDeclaration(al, forModule: true)
        case .Subscript:
            return try moduleSubscriptDeclaration(attrs, al, mods)
        case .Prefix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            return try operatorDeclaration(.Prefix)
        case .Postfix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            return try operatorDeclaration(.Postfix)
        case .Infix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            return try infixOperatorDeclaration()
        default:
            throw ts.fatal(.ExpectedModuleDeclaration)
        }
    }

    private func declarations() throws -> [Declaration] {
        var xs: [Declaration] = []
        while true {
            if case .RightBrace = ts.look().kind {
                break
            }
            xs.append(try declaration())
        }
        return xs
    }

    func declaration(parsedAttrs: [Attribute]? = nil) throws -> Declaration {
        var attrs = try ap.attributes()
        if let pa = parsedAttrs {
            attrs = pa
        }
        let (al, mods) = try disjointModifiers(try ap.declarationModifiers())
        let trackable = ts.look()
        switch ts.match([
            .Import, .Let, .Var, .Typealias, .Func, .Indirect, .Enum,
            .Struct, .Class, .Protocol, .Init, .Deinit, .Extension, .Subscript,
            .Prefix, .Postfix, .Infix
        ]) {
        case .Import:
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeImport)
            }
            return try importDeclaration(attrs, trackable)
        case .Let:
            ScopeManager.enterImplicitScope()
            return try constantDeclaration(attrs, al, mods)
        case .Var:
            ScopeManager.enterImplicitScope()
            return try variableDeclaration(attrs, al, mods)
        case .Typealias:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeTypealias)
            }
            ScopeManager.enterImplicitScope()
            return try typealiasDeclaration(attrs, al)
        case .Func:
            ScopeManager.enterImplicitScope()
            return try functionDeclaration(attrs, al, mods)
        case .Indirect:
            if !ts.test([.Enum]) {
                try ts.error(.ExpectedEnum)
            }
            if mods.count > 0 {
                try ts.error(.ModifierBeforeEnum)
            }
            ScopeManager.enterImplicitScope()
            return try enumDeclaration(attrs, al, isIndirect: true)
        case .Enum:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeEnum)
            }
            ScopeManager.enterImplicitScope()
            return try enumDeclaration(attrs, al)
        case .Struct:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeStruct)
            }
            ScopeManager.enterImplicitScope()
            return try structDeclaration(attrs, al)
        case .Class:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeClass)
            }
            ScopeManager.enterImplicitScope()
            return try classDeclaration(attrs, al)
        case .Protocol:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeProtocol)
            }
            ScopeManager.enterImplicitScope()
            return try protocolDeclaration(attrs, al)
        case .Init:
            return try initializerDeclaration(attrs, al, mods)
        case .Deinit:
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeDeinit)
            }
            return try deinitializerDeclaration(attrs)
        case .Extension:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeExtension)
            }
            if mods.count > 0 {
                try ts.error(.ModifierBeforeExtension)
            }
            ScopeManager.enterImplicitScope()
            return try extensionDeclaration(al)
        case .Subscript:
            return try subscriptDeclaration(attrs, al, mods)
        case .Prefix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            ScopeManager.enterImplicitScope()
            return try operatorDeclaration(.Prefix)
        case .Postfix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            ScopeManager.enterImplicitScope()
            return try operatorDeclaration(.Postfix)
        case .Infix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if al != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            ScopeManager.enterImplicitScope()
            return try infixOperatorDeclaration()
        default:
            throw ts.fatal(.ExpectedDeclaration)
        }
    }

    func typeInheritanceClause() throws -> TypeInheritanceClause? {
        guard ts.test([.Colon]) else {
            return nil
        }
        let x = TypeInheritanceClause()
        if ts.test([.Class]) {
            x.classRequirement = true
            guard ts.test([.Comma]) else {
                return x
            }
        }
        repeat {
            let trackable = ts.look()
            if case let .Identifier(s) = ts.match([identifier]) {
                x.types.append(try tp.identifierType(s, trackable))
            } else {
                try ts.error(.ExpectedTypeIdentifier)
            }
        } while ts.test([.Comma])
        return x
    }

    private func importDeclaration(
        attrs: [Attribute], _ trackable: SourceTrackable
    ) throws -> ImportDeclaration {
        let x = ImportDeclaration(attrs, trackable)
        switch ts.match([
            .Typealias, .Struct, .Class, .Enum, .Protocol, .Var, .Func
        ]) {
        case .Typealias: x.kind = .Typealias
        case .Struct: x.kind = .Struct
        case .Class: x.kind = .Class
        case .Enum: x.kind = .Enum
        case .Protocol: x.kind = .Protocol
        case .Var: x.kind = .Var
        case .Func: x.kind = .Func
        default: break
        }
        var path: [String] = []
        repeat {
            switch ts.match([
                identifier, prefixOperator, binaryOperator, postfixOperator
            ]) {
            case let .Identifier(s): path.append(s)
            case let .PrefixOperator(s): path.append(s)
            case let .BinaryOperator(s): path.append(s)
            case let .PostfixOperator(s): path.append(s)
            default:
                try ts.error(.ExpectedPath)
            }
        } while ts.test([.Dot])
        x.name = path.reduce("", combine: { "\($0).\($1)" })
        try ScopeManager.importModule(x.name, x.sourceInfo)
        return x
    }

    private func moduleConstantDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]
    ) throws -> PatternInitializerDeclaration {
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedConstantName)
        }
        let v = try ScopeManager.createConstant(s, trackable, accessLevel: al)
        guard let annotation = try tp.typeAnnotation() else {
            throw ts.fatal(.ExpectedTypeAnnotationForConstantOrVariable)
        }
        return PatternInitializerDeclaration(
            attrs, al, mods, inits: [(ConstantIdentifierPattern(v), annotation, nil)]
        )
    }

    private func constantDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]
    ) throws -> PatternInitializerDeclaration {
        return PatternInitializerDeclaration(
            attrs, al, mods, inits: try patternInitializerList(false)
        )
    }

    private func moduleVariableDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]
    ) throws -> VariableBlockDeclaration {
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedVariableName)
        }
        let x = VariableBlockDeclaration(
            attrs, al, mods,
            name: try ScopeManager.createVariable(s, trackable, accessLevel: al)
        )
        guard let annotation = try tp.typeAnnotation() else {
            throw ts.fatal(.ExpectedTypeAnnotationForConstantOrVariable)
        }
        x.annotation = annotation
        x.blocks = try getterSetterKeywordBlock()
        return x
    }

    func variableDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]
    ) throws -> Declaration {
        switch ts.look().kind {
        case .Underscore, .LeftParenthesis:
            return PatternInitializerDeclaration(
                attrs, al, mods, inits: try patternInitializerList(true)
            )
        case .Identifier:
            let inits = try patternInitializerList(true)
            if ts.test([.LeftBrace]) {
                if inits.count > 1 {
                    try ts.error(.MultipleVariableWithBlock)
                }
                return try variableBlockDeclaration(attrs, al, mods, ini: inits[0])
            }
            return PatternInitializerDeclaration(attrs, al, mods, inits: inits)
        default:
            throw ts.fatal(.ExpectedVariableIdentifier)
        }
    }

    private func variableBlockDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier], ini: PatternInitializer
    ) throws -> VariableBlockDeclaration {
        guard case let p as VariableIdentifierPattern = ini.0 else {
            throw ts.fatal(.ExpectedIdentifierPatternWithVariableBlock)
        }
        let x = VariableBlockDeclaration(attrs, al, mods, name: p.inst)
        if let annotation = ini.1 {
            x.annotation = annotation
            if let e = ini.2 {
                x.initializer = e
                x.blocks = try willSetDidSetBlock()
                return x
            }
            x.blocks = try getterSetterBlock()
            return x
        }
        guard let e = ini.2 else {
            throw ts.fatal(.ExpectedVariableSpecifierWithBlock)
        }
        x.initializer = e
        x.blocks = try willSetDidSetBlock()
        return x
    }

    private func getterSetterBlock(
        attrs: [Attribute] = [], ahead: Int = 0
    ) throws -> VariableBlocks {
        var x: VariableBlocks!
        switch ts.match([.Get, .Set], ahead: ahead) {
        case .Get:
            ScopeManager.enterScope(.VariableBlock)
            let g = VariableBlock(attrs)
            g.body = try prp.proceduresBlock()
            g.associatedScope = try ScopeManager.leaveScope(.VariableBlock, ts.look())
            if ts.test([.RightBrace]) {
                x = .GetterSetter(getter: g, setter: nil)
            } else {
                let setAttrs = try ap.attributes()
                if !ts.test([.Set]) {
                    try ts.error(.ExpectedSetterAfterGetter)
                }
                let s = try setterBlock(setAttrs)
                x = .GetterSetter(getter: g, setter: s)
            }
        case .Set:
            let s = try setterBlock(attrs)
            let getAttrs = try ap.attributes()
            if !ts.test([.Get]) {
                try ts.error(.ExpectedGetterAfterSetter)
            }
            ScopeManager.enterScope(.VariableBlock)
            let g = VariableBlock(getAttrs)
            g.body = try prp.proceduresBlock()
            g.associatedScope = try ScopeManager.leaveScope(.VariableBlock, ts.look())
            x = .GetterSetter(getter: g, setter: s)
        case .Atmark:
            // Expect getter, setter or procedure beggining with attributes
            // To avoid consuming attributes for procedure, use TokenStream.look only
            let (firstAttrs, i) = try ap.lookAfterAttributes()
            switch ts.look(i).kind {
            case .Get, .Set:
                x = try getterSetterBlock(firstAttrs, ahead: i)
            default:
                break
            }
            fallthrough
        default:
            let g = VariableBlock()
            g.body = try prp.procedures()
            x = .GetterSetter(getter: g, setter: nil)
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterVariableBlock)
        }
        return x
    }

    private func setterBlock(attrs: [Attribute] = []) throws -> VariableBlock {
        ScopeManager.enterScope(.VariableBlock)
        let x = VariableBlock()
        x.attrs = attrs
        if ts.test([.LeftParenthesis]) {
            let trackable = ts.look()
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedSetterVariableName)
            }
            x.param = try ScopeManager.createConstant(s, trackable)
            if !ts.test([.RightParenthesis]) {
                try ts.error(.ExpectedRightParenthesisAfterSetterVariable)
            }
        }
        x.body = try prp.proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(.VariableBlock, ts.look())
        return x
    }

    private func willSetDidSetBlock() throws -> VariableBlocks {
        let attrs = try ap.attributes()
        switch ts.match([.WillSet, .DidSet]) {
        case .WillSet:
            let ws = try setterBlock(attrs)
            if ts.test([.RightBrace]) {
                return .WillSetDidSet(willSetter: ws, didSetter: nil)
            }
            let didSetAttrs = try ap.attributes()
            if !ts.test([.DidSet]) {
                try ts.error(.ExpectedDidSetter)
            }
            let ds = try setterBlock(didSetAttrs)
            if !ts.test([.RightBrace]) {
                try ts.error(.ExpectedRightBraceAfterDidSetterWillSetter)
            }
            return .WillSetDidSet(willSetter: ws, didSetter: ds)
        case .DidSet:
            let ds = try setterBlock(attrs)
            if ts.test([.RightBrace]) {
                return .WillSetDidSet(willSetter: nil, didSetter: ds)
            }
            let willSetAttrs = try ap.attributes()
            if !ts.test([.WillSet]) {
                try ts.error(.ExpectedWillSetter)
            }
            let ws = try setterBlock(willSetAttrs)
            if !ts.test([.RightBrace]) {
                try ts.error(.ExpectedRightBraceAfterDidSetterWillSetter)
            }
            return .WillSetDidSet(willSetter: ws, didSetter: ds)
        default:
            throw ts.fatal(.ExpectedDidSetterWillSetter)
        }
    }

    private func patternInitializerList(isVariable: Bool) throws -> [PatternInitializer] {
        var pi: [PatternInitializer] = []
        repeat {
            let p: Pattern
            if isVariable {
                p = try ptp.declarativePattern(.VariableCreation)
            } else {
                p = try ptp.declarativePattern(.ConstantCreation)
            }
            let a = try tp.typeAnnotation()
            if ts.test([.AssignmentOperator]) {
                pi.append((p, a, try ep.expression()))
            } else {
                pi.append((p, a, nil))
            }
        } while ts.test([.Comma])
        return pi
    }

    private func associatedTypeDeclaration(
        attrs: [Attribute], _ al: AccessLevel?
    ) throws -> TypealiasDeclaration {
        let x = TypealiasDeclaration(attrs, al)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedAssociatedTypeName)
        }
        x.name = try ScopeManager.createType(s, trackable, accessLevel: al)
        x.inherits = try typeInheritanceClause()
        if ts.test([.AssignmentOperator]) {
            x.type = try tp.type()
        }
        return x
    }

    private func typealiasDeclaration(
        attrs: [Attribute], _ al: AccessLevel?
    ) throws -> TypealiasDeclaration {
        let x = TypealiasDeclaration(attrs, al)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedTypealiasName)
        }
        x.name = try ScopeManager.createType(s, trackable, accessLevel: al)
        if !ts.test([.AssignmentOperator]) {
            try ts.error(.ExpectedTypealiasAssignment)
        }
        x.type = try tp.type()
        return x
    }

    private func functionDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier],
        forModule: Bool = false
    ) throws -> FunctionDeclaration {
        let x = FunctionDeclaration(attrs, al, mods)
        var kind: OperatorDeclarationKind?
        for m in mods {
            switch m {
            case .Prefix:
                kind == nil ? kind = .Prefix : try ts.error(.DuplicateOperatorModifier)
            case .Postfix:
                kind == nil ? kind = .Postfix : try ts.error(.DuplicateOperatorModifier)
            default:
                break
            }
        }
        x.name = try functionName(al, kind)
        ScopeManager.enterScope(.Function)
        x.genParam = try gp.genericParameterClause()
        x.params = try parameterClauses(forModule)
        x.throwType = throwType()
        x.returns = try functionResult()
        if forModule {
            if case .LeftBrace = ts.look().kind {
                try ts.error(.ProcedureInModulableFunctionDeclaration)
            }
            x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
            return x
        }
        x.body = try prp.proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
        return x
    }

    private func functionName(
        al: AccessLevel?, _ kind: OperatorDeclarationKind?
    ) throws -> FunctionReference {
        let trackable = ts.look()
        switch ts.match([identifier]) {
        case let .Identifier(s):
            return .Function(
                try ScopeManager.createFunction(s, trackable, accessLevel: al)
            )
        default:
            let o = try operatorName(
                kind ?? .Infix(precedence: 0, associativity: .None),
                error: .ExpectedFunctionName
            )
            return .Operator(
                try ScopeManager.createFunction(o, trackable, accessLevel: al)
            )
        }
    }

    private func parameterClauses(forModule: Bool) throws -> [[Parameter]] {
        var xs: [[Parameter]] = []
        repeat {
            xs.append(try parameterClause(forModule))
        } while ts.look().kind == .LeftParenthesis
        return xs
    }

    private func throwType() -> ThrowType {
        switch ts.match([.Throws, .Rethrows]) {
        case .Throws:
            return .Throws
        case .Rethrows:
            return .Rethrows
        default:
            return .Nothing
        }
    }

    func functionResult() throws -> ([Attribute], Type)? {
        guard ts.test([.Arrow]) else {
            return nil
        }
        return (try ap.attributes(), try tp.type())
    }

    func parameterClause(forModule: Bool) throws -> [Parameter] {
        if !ts.test([.LeftParenthesis]) {
            try ts.error(.ExpectedLeftParenthesisForParameter)
        }
        var pc: [Parameter] = []
        if ts.test([.RightParenthesis]) {
            return pc
        }
        repeat {
            pc.append(try parameter(forModule))
        } while ts.test([.Comma])
        if !ts.test([.RightParenthesis]) {
            try ts.error(.ExpectedRightParenthesisAfterParameter)
        }
        return pc
    }

    private func parameter(forModule: Bool) throws -> Parameter {
        let p = Parameter()
        switch ts.match([.InOut, .Var, .Let]) {
        case .InOut: p.kind = .InOut
        case .Var: p.kind = .Variable
        case .Let: p.kind = .Constant
        default: break
        }
        let name = try parameterName()
        let followName = try parameterName()
        switch name {
        case .NotSpecified:
            throw ts.fatal(.ExpectedInternalParameterName)
        case let .Specified(s, i):
            switch followName {
            case .NotSpecified:
                p.externalName = .NotSpecified
                switch p.kind {
                case .Constant, .None:
                    p.internalName = .SpecifiedConstantInst(
                        try ScopeManager.createConstant(s, i)
                    )
                default:
                    p.internalName = .SpecifiedVariableInst(
                        try ScopeManager.createVariable(s, i)
                    )
                }
            case let .Specified(s, i):
                p.externalName = name
                switch p.kind {
                case .Constant, .None:
                    p.internalName = .SpecifiedConstantInst(
                        try ScopeManager.createConstant(s, i)
                    )
                default:
                    p.internalName = .SpecifiedVariableInst(
                        try ScopeManager.createVariable(s, i)
                    )
                }
            case .Needless:
                p.externalName = name
                p.internalName = .Needless
            default:
                throw ts.fatal(.UnexpectedParameterType)
            }
        case .Needless:
            switch followName {
            case .NotSpecified, .Needless:
                p.externalName = .Needless
                p.internalName = .Needless
            case let .Specified(s, i):
                p.externalName = .Needless
                switch p.kind {
                case .Constant, .None:
                    p.internalName = .SpecifiedConstantInst(
                        try ScopeManager.createConstant(s, i)
                    )
                default:
                    p.internalName = .SpecifiedVariableInst(
                        try ScopeManager.createVariable(s, i)
                    )
                }
            default:
                throw ts.fatal(.UnexpectedParameterType)
            }
        default:
            throw ts.fatal(.UnexpectedParameterType)
        }
        if let a = try tp.typeAnnotation() {
            p.type = a
        } else {
            try ts.error(.ExpectedParameterNameTypeAnnotation)
        }
        switch ts.look().kind {
        case .AssignmentOperator:
            if p.kind == .InOut {
                try ts.error(.InOutParameterWithDefaultArgument)
            }
            ts.next()
            if forModule {
                guard ts.test([.Default]) else {
                    throw ts.fatal(.ExplicitDefaultArgumentInModuleDeclaration)
                }
            } else {
                p.defaultArg = try ep.expression()
            }
        case .PrefixOperator("..."), .BinaryOperator("..."), .PostfixOperator("..."):
            if p.kind != .None {
                try ts.error(.VariadicParameterWithAnotherKind)
            }
            ts.next()
            p.kind = .Variadic
        default:
            break
        }
        return p
    }

    private func parameterName() throws -> ParameterName {
        let info = ts.look().sourceInfo
        switch ts.match([identifier, .Underscore]) {
        case let .Identifier(s):
            return .Specified(s, info)
        case .Underscore:
            return .Needless
        default:
            return .NotSpecified
        }
    }

    private func enumDeclaration(
        attrs: [Attribute], _ al: AccessLevel?,
        isIndirect: Bool = false, forModule: Bool = false
    ) throws -> EnumDeclaration {
        let x = EnumDeclaration(attrs, al, isIndirect: isIndirect)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedEnumName)
        }
        x.name = try ScopeManager.createEnum(s, trackable, node: x)
        ScopeManager.enterScope(.Enum)
        x.genParam = try gp.genericParameterClause()
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForEnumCase)
        }
        if ts.test([.RightBrace]) {
            x.associatedScope = try ScopeManager.leaveScope(.Enum, ts.look())
            return x
        }
        x.members = try enumMembers(isIndirect, forModule: forModule)
        x.associatedScope = try ScopeManager.leaveScope(.Enum, ts.look())
        return x
    }

    private func enumMembers(isIndirect: Bool, forModule: Bool) throws -> [EnumMember] {
        var xs: [EnumMember] = []
        var isUnionStyle = isIndirect
        var isRawValueStyle = false
        while !ts.test([.RightBrace]) {
            let x = try enumMember(isUnionStyle, isRawValueStyle, forModule: forModule)
            switch x {
            case .UnionStyleMember:
                if isRawValueStyle {
                    throw ts.fatal(.RawValueStyleEnumWithUnionStyle)
                }
                isUnionStyle = true
            case .RawValueStyleMember:
                if isUnionStyle {
                    throw ts.fatal(.UnionStyleEnumWithRawValueStyle)
                }
                isRawValueStyle = true
            default:
                break
            }
            xs.append(x)
        }
        return xs
    }

    private func enumMember(
        var isUnionStyle: Bool, _ isRawValueStyle: Bool, forModule: Bool
    ) throws -> EnumMember {
        let attrs = try ap.attributes()
        var isIndirect = false
        if ts.test([.Indirect]) {
            if isRawValueStyle {
                try ts.error(.IndirectWithRawValueStyle)
            }
            isIndirect = true
            isUnionStyle = true
        }
        if !ts.test([.Case]) {
            if isIndirect {
                try ts.error(.ExpectedEnumCaseClause)
            } else {
                if forModule {
                    return .DeclarationMember(try moduleDeclaration(attrs))
                } else {
                    return .DeclarationMember(try declaration(attrs))
                }
            }
        }
        return try enumCaseClause(
            attrs, isIndirect, isUnionStyle: isUnionStyle,
            isRawValueStyle: isRawValueStyle, forModule: forModule
        )
    }

    private func enumCaseClause(
        attrs: [Attribute], _ isIndirect: Bool,
        var isUnionStyle: Bool, var isRawValueStyle: Bool, forModule: Bool
    ) throws -> EnumMember {
        let x = EnumCaseClause(attrs)
        repeat {
            let trackable = ts.look()
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedEnumCaseName)
            }
            let n = try ScopeManager.createEnumCase(s, trackable)
            switch ts.match([.LeftParenthesis, .AssignmentOperator]) {
            case .LeftParenthesis:
                if isRawValueStyle {
                    throw ts.fatal(.AssociatedValueWithRawValueStyle)
                }
                x.cases.append(UnionStyleEnumCase(n, try tp.tupleType()))
                isUnionStyle = true
            case .AssignmentOperator:
                if isUnionStyle {
                    throw ts.fatal(.RawValueAssignmentWithUnionStyle)
                }
                if forModule {
                    throw ts.fatal(.RawValueAssignmentInModuleDeclaration)
                }
                switch ts.match([
                    integerLiteral, floatingPointLiteral, stringLiteral]
                ) {
                case let .IntegerLiteral(i, _):
                    x.cases.append(RawValueStyleEnumCase(n, .IntegerLiteral(i)))
                case let .FloatingPointLiteral(f):
                    x.cases.append(RawValueStyleEnumCase(n, .FloatingPointLiteral(f)))
                case let .StringLiteral(s):
                    x.cases.append(RawValueStyleEnumCase(n, .StringLiteral(s)))
                default:
                    throw ts.fatal(.ExpectedLiteralForRawValue)
                }
                isRawValueStyle = true
            default:
                x.cases.append(EnumCase(n))
            }
        } while ts.test([.Comma])
        if isUnionStyle {
            return .UnionStyleMember(isIndirect: isIndirect, x)
        }
        if isRawValueStyle {
            return .RawValueStyleMember(x)
        }
        return .AlterableStyleMember(x)
    }

    private func structDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, forModule: Bool = false
    ) throws -> StructDeclaration {
        let x = StructDeclaration(attrs, al)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedStructName)
        }
        x.name = try ScopeManager.createStruct(s, trackable, node: x, accessLevel: al)
        ScopeManager.enterScope(.Struct)
        x.genParam = try gp.genericParameterClause()
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForDeclarationBody)
        }
        if forModule {
            x.body = try moduleDeclarations()
        } else {
            x.body = try declarations()
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterDeclarationBody)
        }
        x.associatedScope = try ScopeManager.leaveScope(.Struct, ts.look())
        return x
    }

    private func classDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, forModule: Bool = false
    ) throws -> ClassDeclaration {
        let x = ClassDeclaration(attrs, al)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedClassName)
        }
        x.name = try ScopeManager.createClass(s, trackable, node: x, accessLevel: al)
        ScopeManager.enterScope(.Class)
        x.genParam = try gp.genericParameterClause()
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForDeclarationBody)
        }
        if forModule {
            x.body = try moduleDeclarations()
        } else {
            x.body = try declarations()
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterDeclarationBody)
        }
        x.associatedScope = try ScopeManager.leaveScope(.Class, ts.look())
        return x
    }

    private func protocolDeclaration(
        attrs: [Attribute], _ al: AccessLevel?
    ) throws -> ProtocolDeclaration {
        let x = ProtocolDeclaration(attrs, al)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedProtocolName)
        }
        x.name = try ScopeManager.createProtocol(s, trackable, node: x, accessLevel: al)
        ScopeManager.enterScope(.Protocol)
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForDeclarationBody)
        }
        x.body = try protocolMemberDeclarations()
        x.associatedScope = try ScopeManager.leaveScope(.Protocol, ts.look())
        return x
    }

    private func protocolMemberDeclarations() throws -> [Declaration] {
        var xs: [Declaration] = []
        while !ts.test([.RightBrace]) {
            xs.append(try protocolMemberDeclaration())
        }
        return xs
    }

    private func protocolMemberDeclaration() throws -> Declaration {
        let attrs = try ap.attributes()
        let (al, mods) = try disjointModifiers(try ap.declarationModifiers())
        switch ts.match([.Var, .Typealias, .Func, .Init, .Subscript]) {
        case .Var:
            return try moduleVariableDeclaration(attrs, al, mods)
        case .Typealias:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeTypealias)
            }
            return try associatedTypeDeclaration(attrs, al)
        case .Func:
            return try functionDeclaration(attrs, al, mods, forModule: true)
        case .Init:
            return try initializerDeclaration(attrs, al, mods, forModule: true)
        case .Subscript:
            return try moduleSubscriptDeclaration(attrs, al, mods)
        default:
            throw ts.fatal(.ExpectedDeclaration)
        }
    }

    private func getterSetterKeywordBlock() throws -> VariableBlocks {
        guard ts.test([.LeftBrace]) else {
            throw ts.fatal(.ExpectedGetterSetterKeyword)
        }
        var x: VariableBlocks!
        let attrs = try ap.attributes()
        switch ts.match([.Get, .Set]) {
        case .Get:
            if case .RightBrace = ts.look().kind {
                x = .GetterKeyword(attrs)
            } else {
                let setAttrs = try ap.attributes()
                if !ts.test([.Set]) {
                    try ts.error(.ExpectedSetKeyword)
                }
                x = .GetterSetterKeyword(getAttrs: attrs, setAttrs: setAttrs)
            }
        case .Set:
            let getAttrs = try ap.attributes()
            if !ts.test([.Get]) {
                try ts.error(.ExpectedGetKeyword)
            }
            x = .GetterSetterKeyword(getAttrs: getAttrs, setAttrs: attrs)
        default:
            throw ts.fatal(.ExpectedGetSetKeyword)
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterVariableBlock)
        }
        return x
    }

    private func initializerDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier], forModule: Bool = false
    ) throws -> InitializerDeclaration {
        let x = InitializerDeclaration(attrs, al, mods)
        switch ts.match([.PostfixQuestion, .PostfixExclamation]) {
        case .PostfixQuestion:
            x.failable = .Failable
        case .PostfixExclamation:
            x.failable = .ForceUnwrapFailable
        default:
            x.failable = .Nothing
        }
        ScopeManager.enterScope(.Initializer)
        x.genParam = try gp.genericParameterClause()
        x.params = try parameterClause(forModule)
        if forModule {
            if case .LeftBrace = ts.look().kind {
                try ts.error(.ProcedureInModulableFunctionDeclaration)
            }
            x.associatedScope = try ScopeManager.leaveScope(.Initializer, ts.look())
            return x
        }
        x.body = try prp.proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Initializer, ts.look())
        return x
    }

    private func deinitializerDeclaration(
        attrs: [Attribute]
    ) throws -> DeinitializerDeclaration {
        ScopeManager.enterScope(.Deinitializer)
        let x = DeinitializerDeclaration(attrs, try prp.proceduresBlock())
        x.associatedScope = try ScopeManager.leaveScope(.Deinitializer, ts.look())
        return x
    }

    private func extensionDeclaration(
        al: AccessLevel?, forModule: Bool = false
    ) throws -> ExtensionDeclaration {
        let x = ExtensionDeclaration(al)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedExtendedType)
        }
        x.type = try tp.identifierType(s, trackable)
        ScopeManager.enterScope(.Extension)
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForExtension)
        }
        if forModule {
            x.body = try moduleDeclarations()
        } else {
            x.body = try declarations()
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterExtension)
        }
        x.associatedScope = try ScopeManager.leaveScope(.Extension, ts.look())
        return x
    }

    private func subscriptDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]
    ) throws -> SubscriptDeclaration {
        let x = SubscriptDeclaration(attrs, al, mods)
        ScopeManager.enterScope(.Subscript)
        x.params = try parameterClause(false)
        guard let r = try functionResult() else {
            throw ts.fatal(.ExpectedFunctionResultArrow)
        }
        x.returns = r
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForSubscript)
        }
        x.body = try getterSetterBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Subscript, ts.look())
        return x
    }

    private func moduleSubscriptDeclaration(
        attrs: [Attribute], _ al: AccessLevel?, _ mods: [Modifier]
    ) throws -> SubscriptDeclaration {
        let x = SubscriptDeclaration(attrs, al, mods)
        ScopeManager.enterScope(.Subscript)
        x.params = try parameterClause(true)
        guard let r = try functionResult() else {
            throw ts.fatal(.ExpectedFunctionResultArrow)
        }
        x.returns = r
        x.body = try getterSetterKeywordBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Subscript, ts.look())
        return x
    }

    private func checkReservation(
        kind: OperatorDeclarationKind, _ o: String
    ) -> String? {
        switch kind {
        case .Prefix:
            switch o {
            case "&": return nil
            case "<": return nil
            case "?": return nil
            default: break
            }
        case .Postfix:
            switch o {
            case "!": return nil
            case ">": return nil
            case "?": return nil
            default: break
            }
        case .Infix:
            switch o {
            case "?": return nil
            default: break
            }
        }
        return o
    }

    private func operatorName(
        kind: OperatorDeclarationKind, error: ErrorMessage = .ExpectedOperatorName
    ) throws -> String {
        var name: String?
        switch ts.look().kind {
        case let .PrefixOperator(o):
            name = checkReservation(kind, o)
        case let .BinaryOperator(o):
            name = checkReservation(kind, o)
        case let .PostfixOperator(o):
            name = checkReservation(kind, o)
        case .PostfixExclamation:
            name = checkReservation(kind, "!")
        case .PostfixGraterThan:
            name = checkReservation(kind, ">")
        case .PrefixAmpersand:
            name = checkReservation(kind, "&")
        case .PrefixLessThan:
            name = checkReservation(kind, "<")
        case .BinaryQuestion, .PostfixQuestion, .PrefixQuestion:
            name = nil
        default:
            throw ts.fatal(error)
        }
        guard let n = name else {
            throw ts.fatal(.ReservedOperator)
        }
        ts.next()
        return n
    }

    private func operatorDeclaration(
        kind: OperatorDeclarationKind
    ) throws -> OperatorDeclaration {
        if !ts.test([.Operator]) {
            try ts.error(.ExpectedOperator)
        }
        let trackable = ts.look()
        let o = try operatorName(kind)
        let name = try ScopeManager.createOperator(o, trackable)
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForOperator)
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceForOperator)
        }
        return OperatorDeclaration(kind, name)
    }

    private func infixOperatorDeclaration() throws -> OperatorDeclaration {
        if !ts.test([.Operator]) {
            try ts.error(.ExpectedOperator)
        }
        let trackable = ts.look()
        let o = try operatorName(.Infix(precedence: 0, associativity: .None))
        let name = try ScopeManager.createOperator(o, trackable)
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForOperator)
        }
        let p: Int64
        let a: Associativity
        if case .Precedence = ts.look().kind {
            p = try precedenceClause()
            a = try associativityClause()
        } else {
            a = try associativityClause()
            p = try precedenceClause()
        }
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceForOperator)
        }
        return OperatorDeclaration(.Infix(precedence: p, associativity: a), name)
    }

    private func precedenceClause() throws -> Int64 {
        guard ts.test([.Precedence]) else {
            // precedence value defaults to 100
            return 100
        }
        guard case let .IntegerLiteral(i, decimalDigits: d)
            = ts.match([integerLiteral]) where d else {
                throw ts.fatal(.ExpectedPrecedence)
        }
        return i
    }

    private func associativityClause() throws -> Associativity {
        guard ts.test([.Associativity]) else {
            return .None
        }
        switch ts.match([.Left, .Right, .None]) {
        case .Left:
            return .Left
        case .Right:
            return .Right
        case .None:
            return .None
        default:
            throw ts.fatal(.ExpectedAssociativity)
        }
    }
}
