import Darwin

private typealias FilePointer = UnsafeMutablePointer<FILE>

public class File {
    private let fp: FilePointer
    public let name: String

    public init?(name: String, mode: String) {
        self.name = name
        fp = fopen(name, mode)
        if fp == FilePointer.null() {
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
        let ret = fread(&buffer, UInt(sizeof(CChar)), UInt(size - 1), fp)
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

