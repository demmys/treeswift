/*
 * ProcedureAST
 */
extension Procedure : CustomStringConvertible {
    public var description: String {
        let pre = "(Procedure"
        let post = ")"
        switch self {
        case let .DeclarationProcedure(d):
            return "\(pre) type: declaration \(d)\(post)"
        case let .OperationProcedure(o):
            return "\(pre) type: operation \(o)\(post)"
        case let .FlowProcedure(f):
            return "\(pre) type: flow \(f)\(post)"
        case let .FlowSwitchProcedure(s):
            return "\(pre) type: flow-switch \(s)\(post)"
        }
    }
}

extension Operation : CustomStringConvertible {
    public var description: String {
        let pre = "(Operation"
        let post = ")"
        switch self {
        case let .ExpressionOperation(e):
            return "\(pre) type: expression \(e)\(post)"
        case let .AssignmentOperation(p, e):
            return "\(pre) type: assignment \(p) \(e)\(post)"
        case let .BreakOperation(s):
            return "\(pre) type: break \(s)\(post)"
        case let .ContinueOperation(s):
            return "\(pre) type: continue \(s)\(post)"
        case .FallthroughOperation:
            return "\(pre) type: fallthrough\(post)"
        case let .ReturnOperation(e):
            return "\(pre) type: return \(e)\(post)"
        case let .ThrowOperation(e):
            return "\(pre) type: throw \(e)\(post)"
        }
    }
}

extension PatternMatching : CustomStringConvertible {
    public var description: String {
        return "(PatternMatching \(pat) \(exp) \(rest))"
    }
}

extension ForInit : CustomStringConvertible {
    public var description: String {
        let pre = "(ForInit"
        let post = ")"
        switch self {
        case let .VariableDeclaration(d):
            return "\(pre) type: variable-declaration \(d)\(post)"
        case let .InitOperation(o):
            return "\(pre) type: init \(o)\(post)"
        }
    }
}

extension ElseClause : CustomStringConvertible {
    public var description: String {
        let pre = "(ElseClause"
        let post = ")"
        switch self {
        case let .Else(ps):
            return "\(pre) type: else \(ps)\(post)"
        case let .ElseIf(f):
            return "\(pre) type: else-if \(f)\(post)"
        }
    }
}

extension FlowSwitch : CustomStringConvertible {
    public var description: String {
        return "(FlowSwitch label: \(label) \(cases))"
    }
}

/*
 * DeclarationAST
 */
extension Module : CustomStringConvertible {
    public var description: String {
        return "(Module \(declarations))"
    }
}

extension TopLevelDeclaration : CustomStringConvertible {
    public var description: String {
        return "(TopLevelDeclaration main: \(isMain) \(procedures))"
    }
}

extension ImportKind : CustomStringConvertible {
    public var description: String {
        return self.rawValue.lowercaseString
    }
}

extension VariableBlocks : CustomStringConvertible {
    public var description: String {
        let pre = "(VariableBlocks type:"
        let post =  ")"
        switch self {
        case let .GetterSetter(getter: g, setter: s):
            return "\(pre) getter-setter \(g) \(s)\(post)"
        case let .GetterKeyword(attrs):
            return "\(pre) getter-keyword \(attrs)\(post)"
        case let .GetterSetterKeyword(getAttrs: gattrs, setAttrs: sattrs):
            return "\(pre) getter-setter-keyword \(gattrs) \(sattrs)\(post)"
        case let .WillSetDidSet(willSetter: w, didSetter: d):
            return "\(pre) will-set-did-set \(w) \(d)\(post)"
        }
    }
}

extension VariableBlock : CustomStringConvertible {
    public var description: String {
        return "(VariableBlock \(attrs) \(param) \(body))"
    }
}

extension FunctionReference : CustomStringConvertible {
    public var description: String {
        let name = "type:"
        switch self {
        case let .Function(r): return "\(name) function \(r)"
        case let .Operator(r): return "\(name) operator \(r)"
        }
    }
}

extension ThrowType : CustomStringConvertible {
    public var description: String {
        return "throw-type: \(self.rawValue.lowercaseString)"
    }
}

extension Parameter : CustomStringConvertible {
    public var description: String {
        return "kind: \(kind) \(externalName) \(internalName) \(type) \(defaultArg)"
    }
}

extension ParameterName : CustomStringConvertible {
    public var description: String {
        let name = "parameter-name:"
        switch self {
        case .NotSpecified: return "\(name) not-specified"
        case let .Specified(s, _): return "\(name) specified \(s)"
        case let .SpecifiedConstantInst(i):
            return "\(name) specified-constant-inst \(i)"
        case let .SpecifiedVariableInst(i):
            return "\(name) specified-variable-inst \(i)"
        case .Needless: return "\(name) needless"
        }
    }
}

extension EnumMember : CustomStringConvertible {
    public var description: String {
        let pre = "(EnumMember type:"
        let post =  ")"
        switch self {
        case let .DeclarationMember(d):
            return "\(pre) declaration \(d)\(post)"
        case let .AlterableStyleMember(c):
            return "\(pre) alterable-style \(c)\(post)"
        case let .UnionStyleMember(isIndirect: i, c):
            return "\(pre) union-style indirect: \(i) \(c)\(post)"
        case let .RawValueStyleMember(c):
            return "\(pre) raw-value-style \(c)\(post)"
        }
    }
}

extension EnumCaseClause : CustomStringConvertible {
    public var description: String {
        return "(EnumCaseClause \(attrs) \(cases))"
    }
}

extension RawValueLiteral : CustomStringConvertible {
    public var description: String {
        let pre = "(RawValueLiteral type:"
        let post = ")"
        switch self {
        case let .IntegerLiteral(i): return "\(pre) integer \(i)\(post)"
        case let .FloatingPointLiteral(f): return "\(pre) floating-point \(f)\(post)"
        case let .StringLiteral(s): return "\(pre) string \(s)\(post)"
        }
    }
}

extension FailableType : CustomStringConvertible {
    public var description: String {
        return "failable-type: \(self.rawValue.lowercaseString)"
    }
}

extension OperatorDeclarationKind : CustomStringConvertible {
    public var description: String {
        let name = "operator-declaration-kind:"
        switch self {
        case .Prefix: return "\(name) prefix"
        case .Postfix: return "\(name) postfix"
        case let .Infix(precedence: p, associativity: a):
            return "\(name) infix precedence: \(p) \(a)"
        }
    }
}

extension Associativity : CustomStringConvertible {
    public var description: String {
        return "associativity: \(self.rawValue.lowercaseString)"
    }
}

/*
 * ExpressionAST
 */
extension Expression : CustomStringConvertible {
    public var description: String {
        return "(Expression \(tryType) \(body))"
    }
}

extension TryType : CustomStringConvertible {
    public var description: String {
        return "try-type: \(self.rawValue.lowercaseString)"
    }
}

extension CastType : CustomStringConvertible {
    public var description: String {
        return "cast-type: \(self.rawValue.lowercaseString)"
    }
}

extension ExpressionUnit : CustomStringConvertible {
    public var description: String {
        return "(ExpressionUnit \(pre) \(core) \(posts))"
    }
}

extension ExpressionPrefix : CustomStringConvertible {
    public var description: String {
        let pre = "(ExpressionPrefix type:"
        let post = ")"
        switch self {
        case .Nothing: return "\(pre) nothing\(post)"
        case let .Operator(r): return "\(pre) operator \(r) \(post)"
        case .InOut: return "\(pre) inout\(post)"
        }
    }
}

extension ExpressionPostfix : CustomStringConvertible {
    public var description: String {
        let pre = "(ExpressionPostfix type:"
        let post = ")"
        switch self {
        case let .Member(m): return "\(pre) member \(m) \(post)"
        case .ForcedValue: return "\(pre) foced-value\(post)"
        case let .OptionalChaining(m): return "\(pre) optional-chaining \(m) \(post)"
        case let .Operator(r): return "\(pre) operator \(r)\(post)"
        case let .Subscript(es):
            return "\(pre) subscript \(es)\(post)"
        case let .FunctionCall(t):
            return "\(pre) functioncall \(t)\(post)"
        }
    }
}

extension PostfixMember : CustomStringConvertible {
    public var description: String {
        let name = "postfix-member: "
        switch self {
        case .Initializer: return "\(name)initializer"
        case .PostfixSelf: return "\(name)postfix-self"
        case .DynamicType: return "\(name)dynamic-type"
        case let .ExplicitNamed(s, genArgs: ts):
            return "\(name)explicit-named \(s) \(ts)"
        case let .ExplicitUnnamed(s):
            return "\(name)explicit-unnamed \(s)"
        }
    }
}

extension ExpressionCore : CustomStringConvertible {
    public var description: String {
        return "(ExpressionCore \(value))"
    }
}

extension ExpressionCoreValue : CustomStringConvertible {
    public var description: String {
        let name = "value:"
        switch self {
        case let .Value(r, genArgs: ts): return "\(name) value \(r) \(ts)"
        case let .BindingConstant(i): return "\(name) binding-constant \(i)"
        case let .BindingVariable(i): return "\(name) binding-variable \(i)"
        case let .ImplicitParameter(r, genArgs: ts):
            return "\(name) implicit-parameter \(r) \(ts) "
        case let .Integer(i): return "\(name) integer \(i)"
        case let .FloatingPoint(d): return "\(name) floating-point \(d)"
        case let .StringExpression(s): return "\(name) string \(s)"
        case let .Boolean(b): return "\(name) boolean \(b)"
        case .Nil: return "\(name) nil"
        case let .Array(es): return "\(name) array \(es)"
        case let .Dictionary(ees): return "\(name) dictionary \(ees)"
        case .SelfExpression: return "\(name) self-exnamession"
        case .SelfInitializer: return "\(name) self-initializer"
        case let .SelfMember(s): return "\(name) self-member \(s)"
        case let .SelfSubscript(es): return "\(name) self-subscript \(es)"
        case .SuperClassInitializer: return "\(name) super-class-initializer "
        case let .SuperClassMember(s): return "\(name) super-class-member \(s)"
        case let .SuperClassSubscript(es):
            return "\(name) super-class-subscript \(es)"
        case let .ClosureExpression(c): return "\(name) closure-exnamession \(c)"
        case let .TupleExpression(t): return "\(name) tuple \(t)"
        case let .ImplicitMember(s): return "\(name) implicit-member \(s)"
        case .Wildcard: return "\(name) wildcard"
        }
    }
}

extension Closure : CustomStringConvertible {
    public var description: String {
        return "(Closure \(caps) \(params) \(returns) \(body))"
    }
}

extension CaptureSpecifier: CustomStringConvertible {
    public var description: String {
        let name = "capture-specifier:"
        switch self {
        case .Nothing: return "\(name) nothing"
        case .Weak: return "\(name) weak"
        case .Unowned: return "\(name) unowned"
        case .UnownedSafe: return "\(name) unowned(safe)"
        case .UnownedUnsafe: return "\(name) unowned(unsafe)"
        }
    }
}

extension ClosureParameters : CustomStringConvertible {
    public var description: String {
        let name = "closure-parameters:"
        switch self {
        case .NotProvided: return "\(name) not-provided"
        case let .ExplicitTyped(p): return "\(name) explicit-typed \(p)"
        case let .ImplicitTyped(vs): return "\(name) inplicit-typed \(vs)"
        }
    }
}

/*
 * TypeAST
 */
extension IdentifierType {
    public var description: String {
        return "(IdentifierType \(ref) \(genArgs) \(nestedTypes))"
    }
}

extension ArrayType {
    public var description: String {
        return "(ArrayType \(elem))"
    }
}

extension DictionaryType {
    public var description: String {
        return "(DictionaryType \(key) \(value))"
    }
}

extension TupleType {
    public var description: String {
        return "(TupleType \(elems))"
    }
}

extension TupleTypeElement {
    public var description: String {
        return "(TupleTypeElement inout: \(inOut) variadic: \(variadic) label: \(label) \(attrs) \(type))"
    }
}

extension ProtocolCompositionType {
    public var description: String {
        return "(ProtocolCompositionType \(types))"
    }
}

extension FunctionType {
    public var description: String {
        return "(FunctionType \(throwType) \(arg) \(ret))"
    }
}

extension OptionalType {
    public var description: String {
        return "(OptionalType \(wrapped))"
    }
}

extension ImplicitlyUnwrappedOptionalType {
    public var description: String {
        return "(ImplicitlyUnwrappedOptionalType \(wrapped))"
    }
}

extension MetaType {
    public var description: String {
        return "(MetaType \(type))"
    }
}

extension MetaProtocol {
    public var description: String {
        return "(MetaProtocol \(proto))"
    }
}

/*
 * GenericsAST
 */
extension Requirement : CustomStringConvertible {
    public var description: String {
        let pre = "(Requirement"
        let post = ")"
        switch self {
        case let .Conformance(i, t):
            return "\(pre) type: conformance \(i) \(t)\(post)"
        case let .ProtocolConformance(i, t):
            return "\(pre) type: protocol-conformance \(i) \(t)\(post)"
        case let .SameType(i, t):
            return "\(pre) type: same-type \(i) \(t)\(post)"
        }
    }
}

/*
 * AttributeAST
 */
extension Attribute : CustomStringConvertible {
    public var description: String {
        return "(Attribute \(attr))"
    }
}

extension Modifier : CustomStringConvertible {
    public var description: String {
        let name = "modifier: "
        switch self {
        case .Convenience: return "\(name)convenience"
        case .Dynamic: return "\(name)dynamic"
        case .Final: return "\(name)final"
        case .Lazy: return "\(name)lazy"
        case .Mutating: return "\(name)mutating"
        case .Nonmutating: return "\(name)nonmutating"
        case .Optional: return "\(name)optional"
        case .Override: return "\(name)override"
        case .Required: return "\(name)required"
        case .Static: return "\(name)static"
        case .Weak: return "\(name)weak"
        case .Unowned: return "\(name)unowned"
        case .UnownedSafe: return "\(name)unownedSafe"
        case .UnownedUnsafe: return "\(name)unownedUnsafe"
        case .Class: return "\(name)class"
        case .Infix: return "\(name)infix"
        case .Prefix: return "\(name)prefix"
        case .Postfix: return "\(name)postfix"
        case let .AccessLevelModifier(al): return "\(name)access-level-modifier \(al)"
        }
    }
}

extension AccessLevel : CustomStringConvertible {
    public var description: String {
        return "(AccessLevel \(self.rawValue.lowercaseString))"
    }
}
