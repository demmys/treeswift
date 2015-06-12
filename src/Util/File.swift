import Darwin

private typealias FilePointer = UnsafeMutablePointer<FILE>

public class File {
    private let fp: FilePointer
    public let name: String
    public var baseName: String {
        get {
            var i = name.endIndex
            while i != name.startIndex {
                i = i.predecessor()
                if name[i] == "." {
                    return name[name.startIndex..<i]
                }
            }
            return name
        }
    }

    public init?(name: String, mode: String) {
        self.name = name
        fp = fopen(name, mode)
        if fp == FilePointer(nilLiteral: ()) {
            return nil
        }
    }

    deinit {
        fclose(fp)
    }

    public func isEof() -> Bool {
        return feof(fp) != 0
    }

    public func readString(size: Int) -> String? {
        var buffer = [CChar](count: size, repeatedValue: 0)
        let ret = fread(&buffer, sizeof(CChar), size - 1, fp)
        if ret != 0 {
            if let str = String.fromCString(&buffer) {
                return str
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}

