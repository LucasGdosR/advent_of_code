# Benchmark

Part 1:
- 7645 ns/op
- 0 B/op

Part 2:
- 10726 ns/op
- 0 B/op

# Optimizations

Parse integers and lines in the same loop rather than splitting lines and then parsing each line.

If you were to split lines separately from parsing numbers, it should be done with an iterator that reuses the underlying input, rather than a regular split that allocates a slice for it.

This is embarrassingly parallel by overlapping one line between tasks, but there's not enough work to amortize spawning goroutines and reducing to a single count.

