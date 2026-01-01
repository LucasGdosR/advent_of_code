**How to apply concurrency to this problem**

Part 1 requires dividing the input with commas. This can be done by splitting the input file evenly between workers, and have them adjust the beginning and end of their ranges by searching for the next comma. I did not do this, because...

Part 2 requires ordering. Each box must process the input serially, so I used a single producer to go through the input serially (and solve part 1) and produce jobs for workers. This way, jobs can be processed in parallel if they target different boxes. Having each worker be responsible for a (range of) box(es) instead of sharing boxes lets us do this lockfree, because each slice is only used by one worker. The producer signals it's done by closing channels, and the consumers reduce their local result and send it back to the producer.

1. Producing

The main thread sends a jobs with box indexes, slices, and the operation (either '-' or '=').

2. Consuming

Each worker does the jobs in the order they were sent and waits for the channel to close. They then reduce their local result and send it to the main thread on a buffered shared channel.

3. Merging

Just sum all partial results.

4. Benchmark

While pretty cool in concept, the multithreaded version runs ~6 times slower with 16 threads. The overhead of using a channel for every label in the input is too much. The work may also be poorly distributed among workers.
