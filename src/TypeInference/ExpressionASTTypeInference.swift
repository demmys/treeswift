import AST

extension TypeInference {
    public func visit(node: Expression) throws {
        addConstraint(node, node.body)
        try node.body.accept(self)
    }

    public func visit(node: ExpressionBody) throws {
        addConstraint(node, node.unit)
        try node.unit.accept(self)
    }

    public func visit(node: BinaryExpressionBody) throws {
        let arg = TupleType([TupleTypeElement(node.left), TupleTypeElement(node.right)])
        let functionType = FunctionType(arg, .Nothing, node)
        addConstraint(functionType, node.op)
        try node.left.accept(self)
        try node.right.accept(self)
    }

    public func visit(node: ConditionalExpressionBody) throws {
        addConstraint(node.cond, try boolType())
        addConstraint(node, node.trueSide)
        addConstraint(node.trueSide, node.falseSide)
        try node.cond.accept(self)
        try node.trueSide.accept(self)
        try node.falseSide.accept(self)
    }

    public func visit(node: TypeCastingExpressionBody) throws {
        guard let castType = node.castType else {
            assert(false, "<system error> TypeCastingExpressionBody.castType is nil")
        }
        switch castType {
        case .Is:
            addConstraint(node, try boolType())
        case .As:
            addConstraint(node.unit, node.dist)
            addConstraint(node, node.dist)
        case .ConditionalAs:
            addConstraint(node, OptionalType(node.dist))
        case .ForcedAs:
            addConstraint(node, ImplicitlyUnwrappedOptionalType(node.dist))
        }
        try node.unit.accept(self)
    }

    private func typeOfTuple(tuple: Tuple) -> TupleType {
        let xs = TupleType()
        for (label, exp) in tuple {
            xs.elems.append(TupleTypeElement(label, exp))
        }
        return xs
    }

    public func visit(node: PrefixedExpression) throws {
        if case let .Operator(o) = node.pre {
            let arg = TupleType([TupleTypeElement(node.core)])
            let functionType = FunctionType(arg, .Nothing, node)
            addConstraint(o, functionType)
        }
        // Do not analyze type of PostfixedExpression here.
        // Because member reference has not resolved yet.
        addConstraint(node, node.core)
        try node.core.accept(self)
    }

    public func visit(node: PostfixedExpression) throws {
        switch node.core {
        case let .Core(core):
            addConstraint(node, core)
            try core.accept(self)
        case let .Operator(wrapped, ref):
            let arg = TupleType([TupleTypeElement(wrapped)])
            let functionType = FunctionType(arg, .Nothing, node)
            addConstraint(functionType, ref)
            try wrapped.accept(self)
        case let .FunctionCall(wrapped, tuple):
            let arg = typeOfTuple(tuple)
            // TODO throwable type
            let functionType = FunctionType(arg, .Nothing, node)
            addConstraint(wrapped, functionType)
            try wrapped.accept(self)
            for (_, e) in tuple {
                try e.accept(self)
            }
        case .Member:
            assert(false, "Member dispatch is not implemented")
        case let .Subscript(wrapped, es):
            let arg = TupleType()
            for e in es {
                arg.elems.append(TupleTypeElement(e))
            }
            let functionType = FunctionType(arg, .Nothing, node)
            // TODO not wrapped, subscript of wrapped
            addConstraint(wrapped, functionType)
        case let .ForcedValue(wrapped):
            // TODO treat OptionalType and ImplicitlyUnwrappedOptionaltype as same type
            addConstraint(OptionalType(node), wrapped)
            try wrapped.accept(self)
        case .OptionalChaining:
            assert(false, "Member dispatch is not implemented")
        }
    }

    public func visit(node: ExpressionCore) throws {
        switch node.value {
        case let .Value(r, genArgs: _):
            addConstraint(node, r)
        case let .BindingConstant(i):
            addConstraint(node, i)
        case let .BindingVariable(i):
            addConstraint(node, i)
        case let .ImplicitParameter(r, genArgs: _):
            addConstraint(node, r)
        case .Integer:
            node.type.fixType(try intType())
        case .FloatingPoint:
            node.type.fixType(try floatType())
        case .StringExpression:
            node.type.fixType(try stringType())
        case .Boolean:
            node.type.fixType(try boolType())
        case .Nil:
            addConstraint(node, OptionalType(UnresolvedType()))
        case let .Array(es):
            let elementType = UnresolvedType()
            addConstraint(node, ArrayType(UnresolvedType()))
            for e in es {
                addConstraint(e, elementType)
                try e.accept(self)
            }
        case let .Dictionary(eps):
            let keyType = UnresolvedType()
            let valueType = UnresolvedType()
            addConstraint(node, DictionaryType(keyType, valueType))
            for (e1, e2) in eps {
                addConstraint(e1, keyType)
                addConstraint(e2, valueType)
                try e1.accept(self)
                try e2.accept(self)
            }
        case .SelfExpression, .SelfInitializer, .SelfMember, .SelfSubscript:
            assert(false, "'self' is not implemented")
        case .SuperClassInitializer, .SuperClassMember, .SuperClassSubscript:
            assert(false, "'super' is not implemented")
        case .ClosureExpression:
            assert(false, "Closure expression is not implemented")
        case let .TupleExpression(t):
            addConstraint(node, typeOfTuple(t))
            for (_, e) in t {
                try e.accept(self)
            }
        case .ImplicitMember:
            assert(false, "Implicit member expression is not implemented")
        default:
            break
        }
    }
}
