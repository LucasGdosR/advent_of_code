# Benchmark

Part 1:
- 17399 ns/op
- 0 B/op

Part 2:
- 22741 ns/op
- 0 B/op

# Optimizations

This problem does not require garbage collection, so I moved memory allocation to an outer function so the benchmark can reuse buffers rather than allocate new buffers for every benchmark and trigger garbage collection. That is why There's 0 B/op. This speeds up the benchmark by ~10%. Now onto the actual problem.

Once a number is drawn for the bingo, we must update the boards that hold that number. We could iterate through them all and check if they have the number, but what I did instead was a mapping from numbers to the boards that contain them, and what their index is on that board. In this way, we only touch boards that need updating.

In order to check for bingo, we could always check the updated row and column, or use a bitmap and bitmasks to check. What I measured to be faster was to use a counter por row and column, which means all we need is to check if the counter reached 5.

For summing unmarked cells, I keep a bitset with every marked number, then use it to filter which cells are unmarked. This approach is great for part 2, although part 1 can be marginally faster by marking numbers in the board directly by using the MSB as a marked flag.

For part 2, it is helpful to have a flag indicating the board is already over to avoid keeping updating it. I add an extra cell for this flag.

