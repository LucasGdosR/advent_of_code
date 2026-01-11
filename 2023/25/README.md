**How to apply concurrency to this problem**

Parsing in parallel would be awful, requiring merging the graph later. Better to parse it in a single thread.

Karger's min-cut algorithm is sequential, but since it might need to run multiple times (min-cut is not guaranteed), it is possible to run multiple instances in parallel, and send on a channel to signal that some worker has already found the optimal solution, so everyone can stop. This would require cloning the slice of edges for every worker, although they can share the graph. Each goroutine also has its private union-find.

We could you a channel for signalling the work is done, but using context is the standard way of cancelling work, so that's what I used. Sometimes the multithreaded code is ~20% faster, but it's slower on average. We could batch multiple runs of Karger's algorithm to try and find the sweet spot where MT is usually faster for a serious application.
