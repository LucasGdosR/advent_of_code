# Benchmark

Part 1:
- 781 ns/op
- 0 B/op

Part 2:
- 826 ns/op
- 0 B/op

# Optimizations

All we need to parse is the first character in each line, then we know which command it is, what's the offset for the number, which is always 1 digit, and the index for the next line. Read just the needed bytes rather than the whole input.

This is embarrassingly parallel for part 1, but sequential for part 2. There's not enough work to amortize spawning goroutines and reducing for part 1.

