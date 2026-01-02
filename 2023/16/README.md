
**How to apply concurrency to this problem**

Part 1 could spawn a thread when it hits a bifurcating mirror. Every time there's a branch, it's an opportunity to solve the problem in parallel. I did not do this, as the actual workload lies in Part 2, which is a lot friendlier to multithreading.

Part 2 can be solved in parallel for each entry point, as long as each thread as a private "visited" state. Each thread can get a range of the entries. This is not optimal, as different entry points might take longer to explore. Ideally, this would be implemented with work stealing. That was how I implemented it, though.

1. Producing

Main thread spawns workers who are aware of the range they should process based on their index.

2. Consuming

Each worker processes its range and gets the maximum energized tiles.

3. Merging

The main thread gets the maximum of all worker threads from a channel.

4. Benchmark

This is a problem that takes much longer to process. With 8 cores, multithreading was 4x faster than the singlethreaded solution.

