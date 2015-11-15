import AST

extension TypeInference {
    public func visit(node: Module) throws {
        for d in node.declarations {
            try d.accept(self)
        }
    }

    public func visit(node: TopLevelDeclaration) throws {
        for p in node.procedures {
            try p.accept(self)
        }
    }

    public func visit(node: ImportDeclaration) throws {}

    public func visit(node: PatternInitializerDeclaration) throws {
        for (pattern, annotation, expression) in node.inits {
            if let (type, attrs: _) = annotation {
                pattern.type.fixType(type)
            }
            if let e = expression {
                addConstraint(pattern, e)
                try e.accept(self)
            }
            try pattern.accept(self)
        }
    }

    public func visit(node: VariableBlockDeclaration) throws {
        if let (type, attrs: _) = node.annotation {
            node.name.type.fixType(type)
        }
        if let e = node.initializer {
            addConstraint(node.name, e)
            try e.accept(self)
        }
        guard let blocks = node.blocks else {
            assert(false, "<system error> VariableBlockDeclaration.blocks is nil")
        }
        switch blocks {
        case let .GetterSetter(getter: gb, setter: sb):
            addConstraint(node.name, gb)
            try gb.accept(self)
            if let block = sb {
                addConstraint(node.name, block)
                try block.accept(self)
            }
        case let .WillSetDidSet(willSetter: wb, didSetter: db):
            if let block = wb {
                addConstraint(node.name, block)
                try block.accept(self)
            }
            if let block = db {
                addConstraint(node.name, block)
                try block.accept(self)
            }
        default:
            break
        }
    }

    public func visit(node: VariableBlock) throws {
        if let p = node.param {
            addConstraint(node, p)
        }
        for p in node.body {
            if case let .OperationProcedure(o) = p {
                if case let .ReturnOperation(v) = o {
                    addConstraint(node, v)
                }
            }
            try p.accept(self)
        }
    }

    public func visit(node: TypealiasDeclaration) throws {}

    public func visit(node: FunctionDeclaration) throws {
        let ret: Type
        if let (_, type) = node.returns {
            ret = type
        } else {
            ret = TupleType()
        }
        var functionType = ret
        for (index, argTuple) in node.params.enumerate().reverse() {
            let arg = typeOfParams(argTuple)
            let throwType = index == node.params.count + 1 ? node.throwType : .Nothing
            functionType = FunctionType(arg, throwType, functionType)
        }
        guard let name = node.name else {
            assert(false, "<system error> FunctionDeclaration.name is nil")
        }
        switch name {
        case let .Function(inst):
            inst.type.fixType(functionType)
        case let .Operator(_, inst):
            inst.type.fixType(functionType)
        }

        for p in node.body {
            if case let .OperationProcedure(o) = p {
                if case let .ReturnOperation(v) = o {
                    addConstraint(v, ret)
                }
            }
            try p.accept(self)
        }
    }

    private func typeOfParams(
        params: [Parameter], requireLabelInDefault: Bool = false
    ) -> TupleType {
        let xs = TupleType()
        for p in params {
            let x = TupleTypeElement()
            switch p.kind {
            case .InOut: x.inOut = true
            case .Variadic: x.variadic = true
            default: break
            }
            // label
            guard let externalName = p.externalName else {
                assert(false, "<system error> Parameter.externalName is nil")
            }
            switch externalName {
            case let .Specified(s, _):
                x.label = s
            case .NotSpecified:
                if requireLabelInDefault {
                    guard let internalName = p.internalName else {
                        assert(false, "<system error> Parameter.internalName is nil")
                    }
                    switch internalName {
                    case let .SpecifiedConstantInst(inst):
                        x.label = inst.name
                    case let .SpecifiedVariableInst(inst):
                        x.label = inst.name
                    default:
                        assert(false, "<system error> Not specified internal parameter name")
                    }
                }
            default:
                break
            }
            x.type = p.type.0
            if p.defaultArg != nil {
                assert(false, "Default argument of function declaration is not implemented.")
            }
            xs.elems.append(x)
        }
        return xs
    }

    public func visit(node: EnumDeclaration) throws {
        assert(false, "Enum declaration is not implemented.")
    }

    public func visit(node: StructDeclaration) throws {
        if let inherits = node.inherits {
            for inherit in inherits.types {
                node.name.type.addSubtype(inherit)
            }
        }
        for d in node.body {
            try d.accept(self)
        }
    }

    public func visit(node: ClassDeclaration) throws {
        if let inherits = node.inherits {
            for inherit in inherits.types {
                node.name.type.addSubtype(inherit)
            }
        }
        for d in node.body {
            try d.accept(self)
        }
    }

    public func visit(node: ProtocolDeclaration) throws {
        if let inherits = node.inherits {
            for inherit in inherits.types {
                node.name.type.addSubtype(inherit)
            }
        }
        for d in node.body {
            try d.accept(self)
        }
    }

    public func visit(node: ExtensionDeclaration) throws {
        if let inherits = node.inherits {
            for inherit in inherits.types {
                node.id.ref.inst.type.addSubtype(inherit)
            }
        }
        for d in node.body {
            try d.accept(self)
        }
    }

    public func visit(node: InitializerDeclaration) throws {
        // assert(false, "Initializer declaration is not implemented.")
    }

    public func visit(node: DeinitializerDeclaration) throws {
        assert(false, "Deinitializer declaration is not implemented.")
    }

    public func visit(node: SubscriptDeclaration) throws {
        assert(false, "Subscript declaration is not implemented.")
    }

    public func visit(node: OperatorDeclaration) throws {}
}
