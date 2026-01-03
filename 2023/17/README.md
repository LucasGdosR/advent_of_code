**How to apply concurrency to this problem**

Shortest path problems are typically solved by Dijkstra's algorithm (I implemented A\*, since we can use manhattan distance for this grid problem). This is an example of a greedy algorithm. Greedy algorithms have a direct dependencies between each step, making multithreading impossible. To apply concurrency in this problem, we can either run multiple independent instances of shortest paths (such as part 1 and part 2 in this problem), or use a different algorithm, such as delta-stepping.

**Benchmark

Solving both parts in parallel results in spending as much time as the longer part. This led to a 25% speedup.

