**How to apply concurrency to this problem**

Dropping bricks and checking for collision detection requires sequential processing, so we cannot use concurrency for it. After the bricks have dropped and collided, the rest of the problem is independent, and each brick can be processed in parallel.

1. Producing

Main thread spawns workers who are aware of the range they should process based on their index.

2. Consuming

Each worker processes its range and gets the results.

3. Merging

Sum partial results.

4. Benchmark

Even with simple single threaded naive collision detection, multithreading was nearly twice as fast.

