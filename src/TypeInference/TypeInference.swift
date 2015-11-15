import AST

public class UnresolvedType : Typeable {
    public var type = TypeManager()
}

public class TypeInference : ASTVisitor {
    public var constraints: [(Typeable, Typeable)] = []

    public init() {}

    func boolType() throws -> Type {
        return IdentifierType(
            try ScopeManager.createTypeRef("Bool", SourceInfo.PHANTOM, resolve: true)
        )
    }
    func intType() throws -> Type {
        return IdentifierType(
            try ScopeManager.createTypeRef("Int", SourceInfo.PHANTOM, resolve: true)
        )
    }
    func floatType() throws -> Type {
        return IdentifierType(
            try ScopeManager.createTypeRef("Float", SourceInfo.PHANTOM, resolve: true)
        )
    }
    func stringType() throws -> Type {
        return IdentifierType(
            try ScopeManager.createTypeRef("String", SourceInfo.PHANTOM, resolve: true)
        )
    }

    func addConstraint(x: Typeable, _ y: Typeable) {
        constraints.append((x, y))
    }

    public func infer() throws {
        while var (left, right) = constraints.popLast() {
            guard let t0 = left.type.type else {
                if let t1 = right.type.type {
                    // print("\(left.type.stringify()) <= \(t1.stringify())") // DEBUG
                    left.type.fixType(t1)
                    continue
                }
                // print("\(left.type.stringify()) <= \(right.type.stringify())") // DEBUG
                left.type = right.type
                continue
            }
            guard let t1 = right.type.type else {
                // print("\(right.type.stringify()) <= \(t0.stringify())") // DEBUG
                right.type.fixType(t0)
                continue
            }
            try deconstruct(t0, t1)
        }
    }

    private func deconstruct(t0: Type, _ t1: Type) throws {
        switch t0 {
        case let left as IdentifierType:
            guard case let right as IdentifierType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            guard left.ref.inst.name == right.ref.inst.name else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
        case let left as ArrayType:
            guard case let right as ArrayType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.elem, right.elem)
        case let left as DictionaryType:
            guard case let right as DictionaryType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.key, right.key)
            addConstraint(left.value, right.value)
        case let left as TupleType:
            guard case let right as TupleType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            guard left.elems.count == right.elems.count else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            for (i, leftElem) in left.elems.enumerate() {
                addConstraint(leftElem.type, right.elems[i].type)
            }
        case is ProtocolCompositionType:
            guard case is ProtocolCompositionType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            assert(false, "Protocol composition type is not implemented")
        case let left as FunctionType:
            guard case let right as FunctionType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.arg, right.arg)
            addConstraint(left.ret, right.ret)
        case let left as OptionalType:
            guard case let right as OptionalType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.wrapped, right.wrapped)
        case let left as ImplicitlyUnwrappedOptionalType:
            guard case let right as ImplicitlyUnwrappedOptionalType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.wrapped, right.wrapped)
        case let left as MetaType:
            guard case let right as MetaType = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.reference, right.reference)
        case let left as MetaProtocol:
            guard case let right as MetaProtocol = t1 else {
                throw ErrorReporter.instance.fatal(.TypeNotMatch, nil)
            }
            addConstraint(left.proto, right.proto)
        default:
            assert(false, "<system error> Unexpected type.")
        }
    }

    public func printConstraints() {
        print("[")
        for (t1, t2) in constraints {
            print("\t\(t1.type.stringify()) == \(t2.type.stringify())")
        }
        print("]")
    }
}
