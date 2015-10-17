import Darwin

private typealias FilePointer = UnsafeMutablePointer<FILE>

public enum SeekWhence {
    case SeekSet, SeekCur, SeekEnd

    public var cValue: Int32 {
        switch self {
        case .SeekSet:
            return SEEK_SET
        case .SeekCur:
            return SEEK_CUR
        case .SeekEnd:
            return SEEK_END
        }
    }
}

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
        guard ret != 0 else {
            return nil
        }
        guard let str = String.fromCString(&buffer) else {
            return nil
        }
        return str
    }

    private func gets() -> [CChar]? {
        var buffer = [CChar](count: 256, repeatedValue: 0)
        let ret = fgets(&buffer, 256, fp)
        guard ret != UnsafeMutablePointer<CChar>(nilLiteral: ()) else {
            return nil
        }
        return buffer
    }

    public func readLine() -> String? {
        var bufs: [[CChar]] = []
        while true {
            if let chars = gets() {
                bufs.append(chars)
                if chars[Int(strlen(chars)) - 1] == 10 {
                    break
                }
            } else {
                break
            }
        }
        var line: String = ""
        for var buf in bufs {
            guard let part = String.fromCString(&buf) else {
                return nil
            }
            line.appendContentsOf(part)
        }
        return line
    }

    public func seek(offset: Int, whence: SeekWhence) -> Bool {
        if fseek(fp, offset, whence.cValue) == 0 {
            return true
        }
        return false
    }
}

