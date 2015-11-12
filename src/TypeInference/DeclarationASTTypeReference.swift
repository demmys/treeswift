import AST

extension TypeInference {
    public func visit(node: TopLevelDeclaration) throws {
        for p in node.procedures {
            try p.accept(self)
        }
    }

    public func visit(node: ImportDeclaration) throws {}

    public func visit(node: PatternInitializerDeclaration) throws {
        for (pattern, annotation, expression) in node.inits {
            if let (type, attrs: _) = annotation {
                pattern.type = type
            }
            if let e = expression {
                addConstraint(pattern, e)
                try e.accept(self)
            }
        }
    }

    public func visit(node: VariableBlockDeclaration) throws {
        if let (type, attrs: _) = node.annotation {
            node.name.type = type
        }
        if let e = node.initializer {
            addConstraint(node.name, e)
            try e.accept(self)
        }
        switch node.blocks! {
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
        if node.params.count > 0 {
            assert(false, "Curry function is not implemented.") // TODO
        }
        if node.params.count == 0 {
            assert(false, "<system error> no parameter found.")
        }
        let arg = typeOfParams(node.params[0])
        let ret: Type
        if let (_, type) = node.returns {
            ret = type
        } else {
            ret = TupleType()
        }
        let type = FunctionType(arg, node.throwType, ret)

        switch node.name! {
        case let .Function(inst): inst.type = type
        case let .Operator(inst): inst.type = type
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

    private func typeOfParams(params: [Parameter], requireLabelInDefault: Bool = false) -> TupleType {
        let xs = TupleType()
        for p in params {
            let x = TupleTypeElement()
            switch p.kind {
            case .InOut: x.inOut = true
            case .Variadic: x.variadic = true
            default: break
            }
            // label
            switch p.externalName! {
            case let .Specified(s, _):
                x.label = s
            case .NotSpecified:
                if requireLabelInDefault {
                    switch p.internalName! {
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
                assert(false, "Default argument of function declaration is not implemented.") // TODO
            }
            xs.elems.append(x)
        }
        return xs
    }

    public func visit(node: EnumDeclaration) throws {
    }

    public func visit(node: StructDeclaration) throws {
    }

    public func visit(node: ClassDeclaration) throws {
    }

    public func visit(node: ProtocolDeclaration) throws {
    }

    public func visit(node: InitializerDeclaration) throws {
    }

    public func visit(node: DeinitializerDeclaration) throws {
    }

    public func visit(node: ExtensionDeclaration) throws {
    }

    public func visit(node: SubscriptDeclaration) throws {
    }

    public func visit(node: OperatorDeclaration) throws {
    }
}
