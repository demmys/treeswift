class CharacterStream {
    private let bufferSize = 4096
    private let file: File

    private var queue: String!
    private var index: String.Index!

    init?(_ file: File) {
        self.file = file
        if let str = file.readString(bufferSize) {
            queue = str
            index = queue.startIndex
        } else {
            return nil
        }
    }

    func next() -> Character? {
        if index == queue.endIndex {
            if file.isEof() {
                return nil
            } else {
                queue = file.readString(bufferSize)
                index = queue.startIndex
            }
        }
        let c = queue[index]
        index = index.successor()
        return c
    }
}
