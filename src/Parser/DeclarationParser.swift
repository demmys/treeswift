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

    func declaration(
        parsedAttrs: [Attribute]? = nil
    ) throws -> Declaration {
        var attrs = try ap.attributes()
        if let pa = parsedAttrs {
            attrs = pa
        }
        let almod = try ap.accessLevelModifier()
        var mods = try ap.declarationModifiers()
        switch ts.match([
            .Import, .Let, .Var, .Typealias, .Func, .Indirect, .Enum,
            .Struct, .Class, .Protocol, .Init, .Deinit, .Extension, .Subscript,
            .Prefix, .Postfix, .Infix
        ]) {
        case .Import:
            if almod != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeImport)
            }
            return try importDeclaration(attrs)
        case .Let:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try constantDeclaration(attrs, mods)
        case .Var:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try variableDeclaration(attrs, mods)
        case .Typealias:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeTypealias)
            }
            return try typealiasDeclaration(attrs, almod)
        case .Func:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try functionDeclaration(attrs, mods)
        case .Indirect:
            if !ts.test([.Enum]) {
                try ts.error(.ExpectedEnum)
            }
            if mods.count > 0 {
                try ts.error(.ModifierBeforeEnum)
            }
            return try enumDeclaration(attrs, almod, isIndirect: true)
        case .Enum:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeEnum)
            }
            return try enumDeclaration(attrs, almod)
        case .Struct:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeStruct)
            }
            return try structDeclaration(attrs, almod)
        case .Class:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeClass)
            }
            return try classDeclaration(attrs, almod)
        case .Protocol:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeProtocol)
            }
            return try protocolDeclaration(attrs, almod)
        case .Init:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try initializerDeclaration(attrs, mods)
        case .Deinit:
            if almod != nil || mods.count > 0 {
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
            return try extensionDeclaration(almod)
        case .Subscript:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try subscriptDeclaration(attrs, mods)
        case .Prefix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if almod != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            return try operatorDeclaration(.Prefix)
        case .Postfix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if almod != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
            return try operatorDeclaration(.Postfix)
        case .Infix:
            if attrs.count > 0 {
                try ts.error(.AttributeBeforeOperator)
            }
            if almod != nil || mods.count > 0 {
                try ts.error(.ModifierBeforeOperator)
            }
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

    private func declarations() throws -> [Declaration] {
        var xs: [Declaration] = []
        while !ts.test([.RightBrace]) {
            xs.append(try declaration())
        }
        return xs
    }

    private func importDeclaration(attrs: [Attribute]) throws -> ImportDeclaration {
        let x = ImportDeclaration(attrs)
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
        repeat {
            switch ts.match([
                identifier, prefixOperator, binaryOperator, postfixOperator
            ]) {
            case let .Identifier(s): x.path.append(s)
            case let .PrefixOperator(s): x.path.append(s)
            case let .BinaryOperator(s): x.path.append(s)
            case let .PostfixOperator(s): x.path.append(s)
            default:
                try ts.error(.ExpectedPath)
            }
        } while ts.test([.Dot])
        return x
    }

    private func constantDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> PatternInitializerDeclaration {
        return PatternInitializerDeclaration(
            attrs, mods, isVariable: false, inits: try patternInitializerList()
        )
    }

    func variableDeclaration(
        attrs: [Attribute] = [], _ mods: [Modifier] = []
    ) throws -> Declaration {
        switch ts.look().kind {
        case .Underscore, .LeftParenthesis:
            return PatternInitializerDeclaration(
                attrs, mods, isVariable: true, inits: try patternInitializerList()
            )
        case .Identifier:
            let inits = try patternInitializerList()
            if ts.test([.LeftBrace]) {
                if inits.count > 1 {
                    try ts.error(.MultipleVariableWithBlock)
                }
                return try variableBlockDeclaration(attrs, mods, ini: inits[0])
            }
            return PatternInitializerDeclaration(
                attrs, mods, isVariable: true, inits: inits
            )
        default:
            throw ts.fatal(.ExpectedVariableIdentifier)
        }
    }

    private func variableBlockDeclaration(
        attrs: [Attribute], _ mods: [Modifier], ini: (Pattern, Expression?)
    ) throws -> VariableBlockDeclaration {
        switch ini.0 {
        case let .IdentifierPattern(v):
            guard let e = ini.1 else {
                throw ts.fatal(.ExpectedVariableSpecifierWithBlock)
            }
            let x = VariableBlockDeclaration(attrs, mods, name: v)
            x.specifier = .Initializer(e)
            x.blocks = try willSetDidSetBlock()
            return x
        case let .TypedIdentifierPattern(v, t, attrs):
            let x = VariableBlockDeclaration(attrs, mods, name: v)
            if let e = ini.1 {
                x.specifier = .TypedInitializer(t, attrs, e)
                x.blocks = try willSetDidSetBlock()
                return x
            }
            x.specifier = .TypeAnnotation(t, attrs)
            x.blocks = try getterSetterBlock()
            return x
        default:
            throw ts.fatal(.ExpectedIdentifierPatternWithVariableBlock)
        }
    }

    private func getterSetterBlock(
        attrs: [Attribute] = [], ahead: Int = 0
    ) throws -> VariableBlocks {
        var x: VariableBlocks!
        switch ts.match([.Get, .Set], ahead: ahead) {
        case .Get:
            ScopeManager.enterScope(.Function)
            let g = VariableBlock(attrs)
            g.body = try prp.proceduresBlock()
            g.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
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
            ScopeManager.enterScope(.Function)
            let g = VariableBlock(getAttrs)
            g.body = try prp.proceduresBlock()
            g.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
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
        ScopeManager.enterScope(.Function)
        let x = VariableBlock()
        x.attrs = attrs
        if ts.test([.LeftParenthesis]) {
            let trackable = ts.look()
            guard case let .Identifier(s) = ts.match([identifier]) else {
                throw ts.fatal(.ExpectedSetterVariableName)
            }
            x.param = try ScopeManager.createValue(s, trackable, isVariable: false)
            if !ts.test([.RightParenthesis]) {
                try ts.error(.ExpectedRightParenthesisAfterSetterVariable)
            }
        }
        x.body = try prp.proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
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

    private func patternInitializerList() throws -> [(Pattern, Expression?)] {
        ScopeManager.enterScope(.ValueBinding)
        var pi: [(Pattern, Expression?)] = []
        repeat {
            let p = try ptp.declarativePattern()
            if ts.test([.AssignmentOperator]) {
                pi.append((p, try ep.expression()))
            } else {
                pi.append((p, nil))
            }
        } while ts.test([.Comma])
        return pi
    }

    private func typealiasDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> TypealiasDeclaration {
        let x = TypealiasDeclaration(attrs, mod)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedTypealiasName)
        }
        x.name = try ScopeManager.createType(s, trackable)
        if !ts.test([.AssignmentOperator]) {
            try ts.error(.ExpectedTypealiasAssignment)
        }
        x.type = try tp.type()
        return x
    }

    private func functionDeclaration(
        attrs: [Attribute], _ mods: [Modifier], forProtocol: Bool = false
    ) throws -> FunctionDeclaration {
        let x = FunctionDeclaration(attrs, mods)
        x.name = try functionName()
        ScopeManager.enterScope(.Function)
        x.genParam = try gp.genericParameterClause()
        x.params = try parameterClauses()
        x.throwType = throwType()
        x.returns = try functionResult()
        if forProtocol {
            if case .LeftBrace = ts.look().kind {
                try ts.error(.ProcedureInDeclarationOfProtocol)
            }
            x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
            return x
        }
        x.body = try prp.proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
        return x
    }

    private func functionName() throws -> FunctionReference {
        let trackable = ts.look()
        switch ts.match([
            identifier, prefixOperator, binaryOperator, postfixOperator
        ]) {
        case let .Identifier(s):
            return .Function(try ScopeManager.createValue(s, trackable, isVariable: false))
        case let .PrefixOperator(o):
            return .Operator(try ScopeManager.createOperator(o, trackable))
        case let .BinaryOperator(o):
            return .Operator(try ScopeManager.createOperator(o, trackable))
        case let .PostfixOperator(o):
            return .Operator(try ScopeManager.createOperator(o, trackable))
        default:
            throw ts.fatal(.ExpectedFunctionName)
        }
    }

    private func parameterClauses() throws -> [ParameterClause] {
        var xs: [ParameterClause] = []
        while case .LeftParenthesis = ts.look().kind {
            xs.append(try parameterClause())
        }
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

    func parameterClause() throws -> ParameterClause {
        if !ts.test([.LeftParenthesis]) {
            try ts.error(.ExpectedLeftParenthesisForParameter)
        }
        let pc = ParameterClause()
        if ts.test([.RightParenthesis]) {
            return pc
        }
        repeat {
            pc.body.append(try parameter())
        } while ts.test([.Comma])
        switch ts.look().kind {
        case .PrefixOperator("..."), .BinaryOperator("..."), .PostfixOperator("..."):
            ts.next()
            pc.isVariadic = true
        default:
            break
        }
        if !ts.test([.RightParenthesis]) {
            try ts.error(.ExpectedRightParenthesisAfterParameter)
        }
        return pc
    }

    private func parameter() throws -> Parameter {
        switch ts.look().kind {
        case .InOut, .Var, .Let, .Underscore:
            return try namedParameter()
        case .Atmark, .LeftBracket, .LeftParenthesis, .Protocol:
            return try unnamedParameter()
        case .Identifier:
            switch ts.look(1).kind {
            case .Underscore, .Identifier, .Colon:
                return try namedParameter()
            default:
                return try unnamedParameter()
            }
        default:
            throw ts.fatal(.ExpectedParameter)
        }
    }

    private func namedParameter() throws -> Parameter {
        let p = NamedParameter()
        if ts.test([.InOut]) {
            p.isInout = true
        }
        var isVariable = false
        if case .Var = ts.match([.Var, .Let]) {
            isVariable = true
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
                p.internalName = .SpecifiedInst(
                    try ScopeManager.createValue(s, i, isVariable: isVariable)
                )
            case let .Specified(s, i):
                p.externalName = name
                p.internalName = .SpecifiedInst(
                    try ScopeManager.createValue(s, i, isVariable: isVariable)
                )
            case .Needless:
                p.externalName = name
                p.internalName = .Needless
            default:
                throw ts.fatal(.UnexpectedParameterType)
            }
        case .Needless:
            switch followName {
            case .NotSpecified:
                p.externalName = .NotSpecified
                p.internalName = .Needless
            case let .Specified(s, i):
                p.externalName = .Needless
                p.internalName = .SpecifiedInst(
                    try ScopeManager.createValue(s, i, isVariable: isVariable)
                )
            case .Needless:
                p.externalName = .Needless
                p.internalName = .Needless
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
        if ts.test([.AssignmentOperator]) {
            p.defaultArg = try ep.expression()
        }
        return .Named(p)
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

    private func unnamedParameter() throws -> Parameter {
        let a = try ap.attributes()
        return .Unnamed(a, try tp.type())
    }

    private func enumDeclaration(
        attrs: [Attribute], _ mod: Modifier?, isIndirect: Bool = false
    ) throws -> EnumDeclaration {
        let x = EnumDeclaration(attrs, mod, isIndirect: isIndirect)
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
        x.members = try enumMembers(isIndirect)
        x.associatedScope = try ScopeManager.leaveScope(.Enum, ts.look())
        return x
    }

    private func enumMembers(isIndirect: Bool) throws -> [EnumMember] {
        var xs: [EnumMember] = []
        var isUnionStyle = isIndirect
        var isRawValueStyle = false
        while !ts.test([.RightBrace]) {
            let x = try enumMember(isUnionStyle, isRawValueStyle)
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
        var isUnionStyle: Bool, _ isRawValueStyle: Bool
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
                return .DeclarationMember(try declaration(attrs))
            }
        }
        return try enumCaseClause(
            attrs, isIndirect,
            isUnionStyle: isUnionStyle, isRawValueStyle: isRawValueStyle
        )
    }

    private func enumCaseClause(
        attrs: [Attribute], _ isIndirect: Bool,
        var isUnionStyle: Bool, var isRawValueStyle: Bool
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
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> StructDeclaration {
        let x = StructDeclaration(attrs, mod)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedStructName)
        }
        x.name = try ScopeManager.createStruct(s, trackable, node: x)
        ScopeManager.enterScope(.Struct)
        x.genParam = try gp.genericParameterClause()
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForDeclarationBody)
        }
        x.body = try declarations()
        x.associatedScope = try ScopeManager.leaveScope(.Struct, ts.look())
        return x
    }

    private func classDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> ClassDeclaration {
        let x = ClassDeclaration(attrs, mod)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedClassName)
        }
        x.name = try ScopeManager.createClass(s, trackable, node: x)
        ScopeManager.enterScope(.Class)
        x.genParam = try gp.genericParameterClause()
        x.inherits = try typeInheritanceClause()
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForDeclarationBody)
        }
        x.body = try declarations()
        x.associatedScope = try ScopeManager.leaveScope(.Class, ts.look())
        return x
    }

    private func protocolDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> ProtocolDeclaration {
        let x = ProtocolDeclaration(attrs, mod)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedProtocolName)
        }
        x.name = try ScopeManager.createProtocol(s, trackable, node: x)
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
        let almod = try ap.accessLevelModifier()
        var mods = try ap.declarationModifiers()
        switch ts.match([.Var, .Typealias, .Func, .Init, .Subscript]) {
        case .Var:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try protocolPropertyDeclaration(attrs, mods)
        case .Typealias:
            if mods.count > 0 {
                try ts.error(.ModifierBeforeTypealias)
            }
            return try protocolAssociatedTypeDeclaration(attrs, almod)
        case .Func:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try functionDeclaration(attrs, mods, forProtocol: true)
        case .Init:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try initializerDeclaration(attrs, mods, forProtocol: true)
        case .Subscript:
            if let m = almod {
                mods.insert(m, atIndex: 0)
            }
            return try protocolSubscriptDeclaration(attrs, mods)
        default:
            throw ts.fatal(.ExpectedDeclaration)
        }
    }

    private func protocolPropertyDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> VariableBlockDeclaration {
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedProtocolName)
        }
        let x = VariableBlockDeclaration(
            attrs, mods, name: try ScopeManager.createValue(s, trackable)
        )
        guard let (t, typeAttrs) = try tp.typeAnnotation() else {
            throw ts.fatal(.ExpectedTypeAnnotationForProtocolProperty)
        }
        x.specifier = .TypeAnnotation(t, typeAttrs)
        x.blocks = try getterSetterKeywordBlock()
        return x
    }

    private func protocolSubscriptDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> SubscriptDeclaration {
        let x = SubscriptDeclaration(attrs, mods)
        x.params = try parameterClause()
        guard let r = try functionResult() else {
            throw ts.fatal(.ExpectedFunctionResultArrow)
        }
        x.returns = r
        x.body = try getterSetterKeywordBlock()
        return x
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

    private func protocolAssociatedTypeDeclaration(
        attrs: [Attribute], _ mod: Modifier?
    ) throws -> TypealiasDeclaration {
        let x = TypealiasDeclaration(attrs, mod)
        let trackable = ts.look()
        guard case let .Identifier(s) = ts.match([identifier]) else {
            throw ts.fatal(.ExpectedProtocolAssociatedTypeName)
        }
        x.name = try ScopeManager.createType(s, trackable)
        x.inherits = try typeInheritanceClause()
        if ts.test([.AssignmentOperator]) {
            x.type = try tp.type()
        }
        return x
    }

    private func initializerDeclaration(
        attrs: [Attribute], _ mods: [Modifier], forProtocol: Bool = false
    ) throws -> InitializerDeclaration {
        let x = InitializerDeclaration(attrs, mods)
        switch ts.match([.PostfixQuestion, .PostfixExclamation]) {
        case .PostfixQuestion:
            x.failable = .Failable
        case .PostfixExclamation:
            x.failable = .ForceUnwrapFailable
        default:
            x.failable = .Nothing
        }
        ScopeManager.enterScope(.Function)
        x.genParam = try gp.genericParameterClause()
        x.params = try parameterClause()
        if forProtocol {
            if case .LeftBrace = ts.look().kind {
                try ts.error(.ProcedureInDeclarationOfProtocol)
            }
            x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
            return x
        }
        x.body = try prp.proceduresBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
        return x
    }

    private func deinitializerDeclaration(
        attrs: [Attribute]
    ) throws -> DeinitializerDeclaration {
        ScopeManager.enterScope(.Function)
        let x = DeinitializerDeclaration(attrs, try prp.proceduresBlock())
        x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
        return x
    }

    private func extensionDeclaration(mod: Modifier?) throws -> ExtensionDeclaration {
        let x = ExtensionDeclaration(mod)
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
        x.body = try declarations()
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceAfterExtension)
        }
        x.associatedScope = try ScopeManager.leaveScope(.Extension, ts.look())
        return x
    }

    private func subscriptDeclaration(
        attrs: [Attribute], _ mods: [Modifier]
    ) throws -> SubscriptDeclaration {
        let x = SubscriptDeclaration(attrs, mods)
        ScopeManager.enterScope(.Function)
        x.params = try parameterClause()
        guard let r = try functionResult() else {
            throw ts.fatal(.ExpectedFunctionResultArrow)
        }
        x.returns = r
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForSubscript)
        }
        x.body = try getterSetterBlock()
        x.associatedScope = try ScopeManager.leaveScope(.Function, ts.look())
        return x
    }

    private func operatorDeclaration(
        kind: OperatorDeclarationKind
    ) throws -> OperatorDeclaration {
        if !ts.test([.Operator]) {
            try ts.error(.ExpectedOperator)
        }
        let trackable = ts.look()
        guard case let .BinaryOperator(s) = ts.match([binaryOperator]) else {
            throw ts.fatal(.ExpectedOperatorName)
        }
        let name = try ScopeManager.createOperator(s, trackable)
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
        guard case let .BinaryOperator(s) = ts.match([binaryOperator]) else {
            throw ts.fatal(.ExpectedOperatorName)
        }
        let name = try ScopeManager.createOperator(s, trackable)
        if !ts.test([.LeftBrace]) {
            try ts.error(.ExpectedLeftBraceForOperator)
        }
        let p = try precedenceClause()
        let a = try associativityClause()
        if !ts.test([.RightBrace]) {
            try ts.error(.ExpectedRightBraceForOperator)
        }
        return OperatorDeclaration(.Infix(precedence: p, associativity: a), name)
    }

    private func precedenceClause() throws -> Int64 {
        guard ts.test([.Precedence]) else {
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
