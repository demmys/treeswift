import Darwin

class ErrorInfo {
    private let label = "error:"

    var target: String
    var reason: String

    init(target: String, reason: String) {
        self.target = target
        self.reason = reason
    }

    func print() {
        printStderr("\(target): \(label) \(reason)\n")
    }
    func print(lineNo: Int, charNo: Int, source: String) {
        let m = "\(target):\(lineNo):\(charNo): \(label) \(reason)\n\t\(source)\n"
        printStderr(m)
    }

    private func printStderr(message: String) {
        fputs(message, stderr)
    }
}
