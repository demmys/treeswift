/*
 * ProcedureAST
 */
extension Procedure : CustomStringConvertible {
    public var description: String { get {
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
    } }
}

extension Operation : CustomStringConvertible {
    public var description: String { get {
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
    } }
}

extension PatternMatching : CustomStringConvertible {
    public var description: String { get {
        return "(PatternMatching \(pat) \(exp) \(rest))"
    } }
}

extension ForInit : CustomStringConvertible {
    public var description: String { get {
        let pre = "(ForInit"
        let post = ")"
        switch self {
        case let .VariableDeclaration(d):
            return "\(pre) type: variable-declaration \(d)\(post)"
        case let .InitOperation(o):
            return "\(pre) type: init \(o)\(post)"
        }
    } }
}

extension ElseClause : CustomStringConvertible {
    public var description: String { get {
        let pre = "(ElseClause"
        let post = ")"
        switch self {
        case let .Else(ps):
            return "\(pre) type: else \(ps)\(post)"
        case let .ElseIf(f):
            return "\(pre) type: else-if \(f)\(post)"
        }
    } }
}

extension FlowSwitch : CustomStringConvertible {
    public var description: String { get {
        return "(FlowSwitch label: \(label) \(cases))"
    } }
}

/*
 * DeclarationAST
 */
extension Modifier : CustomStringConvertible {
    public var description: String { get {
        return "modifier: \(self.rawValue.lowercaseString)"
    } }
}

extension VariableDeclaration {
    public var description: String { get {
        let pre = "(VariableDeclaration"
        let post = ")"
        switch self {
        case let .PatternInitializerList(pi):
            return "\(pre) type: pattern-initializer-list \(pi)\(post)"
        }
    } }
}

extension ParameterClause : CustomStringConvertible {
    public var description: String { get {
        return "(ParameterClause variadic: \(isVariadic) \(body))"
    } }
}

extension Parameter: CustomStringConvertible {
    public var description: String { get {
        let name = "parameter:"
        switch self {
        case let .Named(p): return "\(name) named \(p)"
        case let.Unnamed(attrs, t): return "\(name) unnamed \(attrs) \(t)"
        }
    } }
}

extension NamedParameter : CustomStringConvertible {
    public var description: String { get {
        return "inout: \(isInout) variable: \(isVariable) \(externalName) \(internalName) \(type) \(defaultArg)"
    } }
}

extension ParameterName : CustomStringConvertible {
    public var description: String { get {
        let name = "parameter-name:"
        switch self {
        case .NotSpecified: return "\(name) not-specified"
        case let .Specified(r): return "\(name) specified \(r)"
        case .Needless: return "\(name) needless"
        }
    } }
}

/*
 * ExpressionAST
 */
extension Expression : CustomStringConvertible {
    public var description: String { get {
        return "(Expression \(tryType) \(body))"
    } }
}

extension TryType : CustomStringConvertible {
    public var description: String { get {
        let name = "try-type: "
        switch self {
        case .Nothing: return "\(name)nothing"
        case .Try: return "\(name)try"
        case .ForcedTry: return "\(name)forced-try"
        }
    } }
}

extension CastType : CustomStringConvertible {
    public var description: String { get {
        let name = "cast-type: "
        switch self {
        case .Is: return "\(name)is"
        case .As: return "\(name)as"
        case .ConditionalAs: return "\(name)conditional-as-type"
        case .ForcedAs: return "\(name)forced-as-type"
        }
    } }
}

extension ExpressionUnit : CustomStringConvertible {
    public var description: String { get {
        return "(ExpressionUnit \(pre) \(core) \(posts))"
    } }
}

extension ExpressionPrefix : CustomStringConvertible {
    public var description: String { get {
        let pre = "(ExpressionPrefix type:"
        let post = ")"
        switch self {
        case .Nothing: return "\(pre) nothing\(post)"
        case let .Operator(r): return "\(pre) operator \(r) \(post)"
        case .InOut: return "\(pre) inout\(post)"
        }
    } }
}

extension ExpressionPostfix : CustomStringConvertible {
    public var description: String { get {
        let pre = "(ExpressionPostfix type:"
        let post = ")"
        switch self {
        case .Initializer: return "\(pre) initializer\(post)"
        case .PostfixSelf: return "\(pre) postfix-self\(post)"
        case .DynamicType: return "\(pre) dynamic-type\(post)"
        case .ForcedValue: return "\(pre) foced-value\(post)"
        case .OptionalChaining: return "\(pre) optional-chaining\(post)"
        case let .Operator(r): return "\(pre) operator \(r)\(post)"
        case let .ExplicitNamedMember(r, genArgs: ts):
            return "\(pre) explicit-named-member \(r) \(ts)\(post)"
        case let .ExplicitUnnamedMember(r):
            return "\(pre) explicit-unnamed-member \(r)\(post)"
        case let .Subscript(es):
            return "\(pre) subscript \(es)\(post)"
        case let .FunctionCall(t):
            return "\(pre) functioncall \(t)\(post)"
        }
    } }
}

extension ExpressionCore : CustomStringConvertible {
    public var description: String { get {
        let pre = "(ExpressionCore type:"
        let post = ")"
        switch self {
        case let .Value(r, genArgs: ts): return "\(pre) value \(r) \(ts)\(post)"
        case let .Integer(i): return "\(pre) integer \(i)\(post)"
        case let .FloatingPoint(d): return "\(pre) floating-point \(d)\(post)"
        case let .StringExpression(s): return "\(pre) string \(s)\(post)"
        case let .Boolean(b): return "\(pre) boolean \(b)\(post)"
        case .Nil: return "\(pre) nil\(post)"
        case let .Array(es): return "\(pre) array \(es)\(post)"
        case let .Dictionary(ees): return "\(pre) dictionary \(ees)\(post)"
        case .SelfExpression: return "\(pre) self-expression\(post)"
        case .SelfInitializer: return "\(pre) self-initializer\(post)"
        case let .SelfMember(r): return "\(pre) self-member \(r)\(post)"
        case let .SelfSubscript(es): return "\(pre) self-subscript \(es)\(post)"
        case .SuperClassInitializer: return "\(pre) super-class-initializer \(post)"
        case let .SuperClassMember(r): return "\(pre) super-class-member \(r)\(post)"
        case let .SuperClassSubscript(es):
            return "\(pre) super-class-subscript \(es)\(post)"
        case let .ClosureExpression(c): return "\(pre) closure-expression \(c)\(post)"
        case let .TupleExpression(t): return "\(pre) tuple \(t)\(post)"
        case let .ImplicitMember(r): return "\(pre) implicit-member \(r)\(post)"
        case .Wildcard: return "\(pre) wildcard\(post)"
        }
    } }
}

extension Closure : CustomStringConvertible {
    public var description: String { get {
        return "(Closure \(caps) \(params) \(returns) \(body))"
    } }
}

extension CaptureSpecifier: CustomStringConvertible {
    public var description: String { get {
        let name = "capture-specifier:"
        switch self {
        case .Nothing: return "\(name) nothing"
        case .Weak: return "\(name) weak"
        case .Unowned: return "\(name) unowned"
        case .UnownedSafe: return "\(name) unowned(safe)"
        case .UnownedUnsafe: return "\(name) unowned(unsafe)"
        }
    } }
}

extension ClosureParameters : CustomStringConvertible {
    public var description: String { get {
        let name = "closure-parameters:"
        switch self {
        case .NotProvided: return "\(name) not-provided"
        case let .ExplicitTyped(p): return "\(name) explicit-typed \(p)"
        case let .ImplicitTyped(vs): return "\(name) inplicit-typed \(vs)"
        }
    } }
}

/*
 * TypeAST
 */
extension IdentifierType {
    public var description: String { get {
        return "(IdentifierType \(ref) \(genArgs))"
    } }
}

extension ArrayType {
    public var description: String { get {
        return "(ArrayType \(elem))"
    } }
}

extension DictionaryType {
    public var description: String { get {
        return "(DictionaryType \(key) \(value))"
    } }
}

extension TupleType {
    public var description: String { get {
        return "(TupleType variadic: \(variadic) \(elems))"
    } }
}

extension TupleTypeElement {
    public var description: String { get {
        return "(TupleTypeElement inout: \(inOut) label: \(label) \(attrs) \(type))"
    } }
}

extension ProtocolCompositionType {
    public var description: String { get {
        return "(ProtocolCompositionType \(types))"
    } }
}

extension FunctionType {
    public var description: String { get {
        return "(FunctionType \(throwType) \(arg) \(ret))"
    } }
}

extension ThrowType {
    public var description: String { get {
        let name = "throw-type:"
        switch self {
        case .Nothing: return "\(name) nothing"
        case .Throws: return "\(name) throws"
        case .Rethrows: return "\(name) rethrows"
        }
    } }
}

extension OptionalType {
    public var description: String { get {
        return "(OptionalType \(wrapped))"
    } }
}

extension ImplicitlyUnwrappedOptionalType {
    public var description: String { get {
        return "(ImplicitlyUnwrappedOptionalType \(wrapped))"
    } }
}

extension MetaType {
    public var description: String { get {
        return "(MetaType \(type))"
    } }
}

extension MetaProtocol {
    public var description: String { get {
        return "(MetaProtocol \(proto))"
    } }
}

/*
 * PatternAST
 */
extension Pattern : CustomStringConvertible {
    public var description: String { get {
        let pre = "(Pattern"
        let post = ")"
        switch self {
        case .IdentityPattern:
            return "\(pre) type: identity\(post)"
        case .BooleanPattern:
            return "\(pre) type: boolean\(post)"
        case let .OptionalBindingConstantPattern(p):
            return "\(pre) type: optional-binding-constant \(p)\(post)"
        case let .OptionalBindingVariablePattern(p):
            return "\(pre) type: optional-binding-variable \(p)\(post)"
        case let .IdentifierPattern(r):
            return "\(pre) type: identifier \(r)\(post)"
        case let .TypedIdentifierPattern(r, t, attrs):
            return "\(pre) type: type-identifier \(r) \(t) \(attrs)\(post)"
        case .WildcardPattern:
            return "\(pre) type: wildcard-pattern)\(post)"
        case let .TypedWildcardPattern(t, attrs):
            return "\(pre) type: typed-wildcard \(t) \(attrs)\(post)"
        case let .TuplePattern(pt):
            return "\(pre) type: tuple \(pt)\(post)"
        case let .VariableBindingPattern(p):
            return "\(pre) type: variable-binding \(p)\(post)"
        case let .ConstantBindingPattern(p):
            return "\(pre) type: constant-binding \(p)\(post)"
        case let .EnumCasePattern(r, pt):
            return "\(pre) type: enum-case \(r) \(pt)\(post)"
        case let .TypePattern(t):
            return "\(pre) type: type \(t)\(post)"
        case let .ExpressionPattern(e):
            return "\(pre) type: expression \(e)\(post)"
        case let .OptionalPattern(p):
            return "\(pre) type: optional \(p)\(post)"
        case let .TypeCastingPattern(p, t):
            return "\(pre) type: typeCasting \(p) \(t)\(post)"
        }
    } }
}

/*
 * GenericsAST
 */
extension Requirement : CustomStringConvertible {
    public var description: String { get {
        let pre = "(Requirement"
        let post = ")"
        switch self {
        case let .Conformance(i, t):
            return "\(pre) type: conformance \(i) \(t)\(post)"
        case let .SameType(i, t):
            return "\(pre) type: same-type \(i) \(t)\(post)"
        }
    } }
}

/*
 * AttributeAST
 */
extension Attribute : CustomStringConvertible {
    public var description: String { get {
        return "(Attribute \(attr))"
    } }
}
