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
        case .Closure: return "\(pre) closure\(post)"
        case let .TupleExpression(t): return "\(pre) tuple \(t)\(post)"
        case let .ImplicitMember(r): return "\(pre) implicit-member \(r)\(post)"
        case .Wildcard: return "\(pre) wildcard\(post)"
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
 * AttributeAST
 */
extension Attribute : CustomStringConvertible {
    public var description: String { get {
        return "(Attribute \(attr))"
    } }
}
