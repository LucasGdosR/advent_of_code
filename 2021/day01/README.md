# Benchmark

Part 1:
- 4909 ns/op
- 0 B/op

Part 2:
- 6064 ns/op
- 0 B/op

# Optimizations

Parse integers and lines in the same loop rather than splitting lines and then parsing each line.

If you were to split lines separately from parsing numbers, it should be done with an iterator that reuses the underlying input, rather than a regular split that allocates a slice for it.

Numbers don't need to be parsed, they just need to be ordered. We can just shift each digit 8 to the left, so there's no overlap between them, and then compare the resulting number. This maintains order and uses fewer instructions.

Ordering branches so the most common branch comes first also slightly speeds up the program.

This is embarrassingly parallel by overlapping one line between tasks, but there's not enough work to amortize spawning goroutines and reducing to a single count.

