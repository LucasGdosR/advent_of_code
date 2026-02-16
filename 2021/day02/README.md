# Benchmark

Part 1:
- 691 ns/op
- 0 B/op

Part 2:
- 767 ns/op
- 0 B/op

# Optimizations

All we need to parse is the first character in each line, then we know which command it is, what's the offset for the number, which is always 1 digit, and the index for the next line. Read just the needed bytes rather than the whole input.

For part 1, we can keep a count of how many '0' adjustments to make rather than parsing the actual input for every line, and then apply the adjustment just once.

Instead of using a switch statement, we can use if-statements ordered by the most common case.

This is embarrassingly parallel for part 1, but sequential for part 2. There's not enough work to amortize spawning goroutines and reducing for part 1.

