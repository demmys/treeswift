import Util

protocol CharacterPeeper {
    func look() -> Character?
    func lookAhead() -> Character?
}

class CharacterStream : CharacterPeeper {
    private let bufferSize = 4096
    private let file: File

    private var queue: String!
    private var index: String.Index!

    var lineNo: Int = 1
    var charNo: Int = 1

    init?(_ file: File) {
        self.file = file
        if let str = file.readString(bufferSize) {
            queue = str
            index = queue.startIndex
        } else {
            return nil
        }
    }

    func look() -> Character? {
        if index >= queue.endIndex {
            if file.isEof() {
                return nil
            } else {
                queue = file.readString(bufferSize)
                index = queue.startIndex
            }
        }
        return queue[index]
    }

    func lookAhead() -> Character? {
        if index.successor() >= queue.endIndex {
            if file.isEof() {
                return nil
            } else {
                queue = String(queue[index])
                queue.extend(file.readString(bufferSize)!)
                index = queue.startIndex
            }
        }
        return queue[index.successor()]
    }

    func consume() {
        if let c = look() {
            switch c {
            case "\n":
                ++lineNo
                fallthrough
            case "\r":
                charNo = 1
            case "\0", "\u{000b}", "\u{000c}":
                break
            default:
                ++charNo;
            }
        }
        index = index.successor()
    }
}
