# Benchmark

Part 1:
- 6256 ns/op
- 96 B/op

Part 2:
- 3240 ns/op
- 0 B/op

# Optimizations

For part 1, instead of parsing 0 vs 1 or subtracting '0' from every byte, just sum every byte and compensate by calculating the majority summing `lineCount*'0'`. Nevermind `epsilon`, it is just the full bitmask XOR gamma.

For part 2, keep slices of indexes into input and filter those indexes with increasing offsets.

