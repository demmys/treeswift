import Darwin

public struct StderrOutputStream : OutputStreamType {
    public mutating func write(string: String) {
        fputs(string, stderr)
    }
}

public var STDERR = StderrOutputStream()
