import Darwin

class ErrorInfo {
    private let label = "error:"

    private var reason: String

    var lineNo: Int?
    var charNo: Int?
    var source: String?

    init(reason: String) {
        self.reason = reason
    }

    func print(target: String) {
        var message = "\(target):"
        if let l = lineNo {
            if let c = charNo {
                message = message + "\(l):\(c):"
            }
        }
        message = message + " \(label) \(reason)\n"
        if let s = source {
            message = message + "\t\(s)\n"
        }
        printStderr(message)
    }
    func print(target: String, lineNo: Int, charNo: Int, source: String) {
        self.lineNo = lineNo
        self.charNo = charNo
        self.source = source
        print(target)
    }

    private func printStderr(message: String) {
        fputs(message, stderr)
    }
}
