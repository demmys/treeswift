public enum OptionParseError : ErrorType {
    case InvalidOption(String)
    case ArgumentNotProvided(String)
}

private struct OptionBody<Representation> {
    let constructor: String? -> Representation
    let requireArgument: Bool
}

public class OptionParser<Representation> {
    private var options: [String:OptionBody<Representation>] = [:]

    public init() {}

    public func setOption(
        option: String, _ constructor: String? -> Representation,
        requireArgument: Bool
    ) {
        options[option] = OptionBody<Representation>(
            constructor: constructor, requireArgument: requireArgument
        )
    }

    public func parse() throws -> (result: [Representation], remains: [String]) {
        var result: [Representation] = []
        var remains = [Process.arguments[0]]
        for var i = 1; i < Process.arguments.count; ++i {
            let a = Process.arguments[i]
            guard a[a.startIndex] == "-" else {
                remains.append(a)
                continue
            }
            let option = String(a.characters.dropFirst())
            if let o = options[option] {
                if o.requireArgument {
                    guard Process.arguments.count > i + 1 else {
                        throw OptionParseError.ArgumentNotProvided(option)
                    }
                    result.append(o.constructor(Process.arguments[++i]))
                } else {
                    result.append(o.constructor(nil))
                }
            } else {
                throw OptionParseError.InvalidOption(option)
            }
        }
        return (result: result, remains: remains)
    }
}
