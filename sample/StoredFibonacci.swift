func storedFibonacci(n: Int) -> Int {
    var fibs: [Int] = [1, 1]
    for var i: Int = 2; i <= n; ++i {
        fibs.append(fibs[i - 2] + fibs[i - 1])
    }
    return fibs[n]
}

println(storedFibonacci(45))
for var i: Int = 0; i < 10000; ++i {
    storedFibonacci(45)
}
