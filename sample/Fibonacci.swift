func fibonacci(n: Int) -> Int {
    if n < 2  {
        return 1
    }
    return fibonacci(n - 2) + fibonacci(n - 1)
}

print(fibonacci(45))
