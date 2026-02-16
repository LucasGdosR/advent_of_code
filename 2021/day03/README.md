# Benchmark

Part 1:
- 3689 ns/op
- 96 B/op

Part 2:
- 3968 ns/op
- 0 B/op

# Optimizations

For part 1, instead of parsing 0 vs 1 or subtracting '0' from every byte, just sum every byte and compensate by calculating the majority summing `lineCount*'0'`. Nevermind `epsilon`, it is just the full bitmask XOR gamma.

Part 1's runtime boils down to a single loop with a single add and store. I unrolled it manually to greatly improve performance. This was a good tradeoff.

For part 2, keep slices of indexes into input and filter those indexes with increasing offsets. Part 2 could benefit from loop unrolling, but not nearly as much, so I left it out.

