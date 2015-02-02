func memorizedFibonacci(n: Int) -> Int {
    var a: Int = 0
    var b: Int = 1
    for var i: Int = 0; i < n; ++i {
        var t: Int = a
        a = b
        b += t
    }
    return b
}

memorizedFibonacci(45)
for var i: Int = 0; i < 10000000; ++i {
    memorizedFibonacci(45)
}
