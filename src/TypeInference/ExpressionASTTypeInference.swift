import AST

extension TypeInference {
    public func visit(node: Expression) throws {
        addConstraint(node, node.body)
        try node.body.accept(self)
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
        switch node.castType! {
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

    public func visit(node: ExpressionUnit) throws {
        var postfixedType: Typeable = node.core
        for post in node.posts {
            switch post {
            case let .Operator(o):
                let arg = TupleType([TupleTypeElement(postfixedType)])
                let ret = UnresolvedType()
                let functionType = FunctionType(arg, .Nothing, ret)
                addConstraint(o, functionType)
                postfixedType = ret
            case let .FunctionCall(tuple):
                let arg = typeOfTuple(tuple)
                let ret = UnresolvedType()
                // TODO throwable type
                let functionType = FunctionType(arg, .Nothing, ret)
                addConstraint(postfixedType, functionType)
                postfixedType = ret
            case .Member, .OptionalChaining:
                    assert(false, "Member expression is not implemented")
            case .Subscript:
                    assert(false, "Subscription is not implemented")
            case .ForcedValue:
                switch postfixedType {
                case let t as OptionalType:
                    postfixedType = t.wrapped
                case let t as ImplicitlyUnwrappedOptionalType:
                    postfixedType = t.wrapped
                default:
                    try ErrorReporter.instance.error(.UnwrappingNotAOptionalType, nil)
                }
            }
        }
        if case let .Operator(o) = node.pre! {
            let arg = TupleType([TupleTypeElement(postfixedType)])
            let functionType = FunctionType(arg, .Nothing, node)
            addConstraint(o, functionType)
        }
        try node.core.accept(self)
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
            node.type = try intType()
        case .FloatingPoint:
            node.type = try floatType()
        case .StringExpression:
            node.type = try stringType()
        case .Boolean:
            node.type = try boolType()
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
