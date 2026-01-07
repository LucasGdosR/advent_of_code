**How to apply concurrency to this problem**

Finding the longest path is an NP-hard problem. Hard problems make multithreading worth it. Finding the vertices in the input could be done in parallel, and so could connecting them with edges. This would require synchronization to append to slices or put into maps, so it's really nor worth it. The main dish of the problem is doing backtracking search to enumerate every possible path. This enumeration can happen in parallel.

My approach was doing depth first search and spawning new goroutines up to a certain cutoff point. Experimentally, the best cutoff was depth 10. Considering each vertex splits into 2 (although it's sometimes 3), this means at most 1024 paths are concurrently explored. This approach led to a 9 times speedup with 16 threads.

No more than 16 goroutines can run at once, so why does performance increase up to 1024? That is because of load balancing. With fewer goroutines, it is more likely that quite a few long paths are concentrated in just a single goroutine, and it becomes the bottleneck. This load balancing could be achieved in a more efficient manner with workstealing. I should try implementing it someday.
