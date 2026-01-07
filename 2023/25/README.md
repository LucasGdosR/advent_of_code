**How to apply concurrency to this problem**

Parsing in parallel would be awful, requiring merging the graph later. Better to parse it in a single thread.

Karger's min-cut algorithm is sequential, but since it might need to run multiple times (min-cut is not guaranteed), it is possible to run multiple instances in parallel, and send on a channel to signal that some worker has already found the optimal solution, so everyone can stop. This would require cloning the slice of edges for every worker, although they can share the graph. I did not implement it, so... TODO: implement multiple workers running on different randomized instances and communicating through a channel for termination.
