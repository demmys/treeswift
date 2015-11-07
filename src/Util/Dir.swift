import Darwin

private typealias DirPointer = UnsafeMutablePointer<DIR>
private typealias DirEnt = UnsafeMutablePointer<dirent>

public class Dir {
    private let dp: DirPointer
    private let name: String

    public init?(name: String) {
        self.name = name
        dp = opendir(name)
        if dp == DirPointer(nilLiteral: ()) {
            return nil
        }
    }

    deinit {
        closedir(dp)
    }

    public func read() -> [String] {
        var entries: [String] = []
        while true {
            let dirEntry = readdir(dp)
            guard dirEntry != DirEnt(nilLiteral: ()) else {
                break
            }
            let entry = withUnsafePointer(&dirEntry.memory.d_name, { p -> String? in
                String.fromCString(unsafeBitCast(p, UnsafePointer<Int8>.self))
            })
            entries.append(entry!)
        }
        return entries
    }
}
