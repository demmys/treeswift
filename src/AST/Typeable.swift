public protocol Typeable {
    var type: TypeManager { get set }
}

public class TypeManager {
    private static var nextID: Int = 0
    private var id = nextID++
    private var _type: Type?
    public var type: Type? {
        return _type
    }
    private var subtypes: [IdentifierType] = []

    public init() {}

    public func fixType(type: Type) {
        guard self._type == nil else {
            assert(false, "<system error> type already fixed as '\(_type.dynamicType)'")
            exit(1)
        }
        self._type = type
    }

    public func addSubtype(type: IdentifierType) {
        subtypes.append(type)
    }

    public func stringify() -> String {
        if let t = type {
            return t.stringify()
        }
        return "T_\(id)"
    }
}
