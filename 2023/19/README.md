**How to apply concurrency to this problem**

Parsing workflows in parallel is finicky because we don't really know where they end in the file. We could read the file as a byte slice and arbitrarily jump to spots where we hope to parse workflows, adjust based on line breaks, and skip when the line starts with '{', representing a part. We'd also need to use a `sync.Map` for this case. I did it singlethreaded, but it could be done multithreaded.

Part 1 could be parsed and solved in parallel, and this would be particularly suitable with a byte slice with each goroutine taking care of a chunk of the parts, or sending each part on a tasks channel if load balancing is important. I just did this part in parallel with part 2.

Part 2 has a few different approaches. The best approach is that of runtimes such as OpenCilk or Rayon where the programmer marks a function call as spawning a task, and the runtime decides if it spawns a thread or not.

I did something like this, except Go's runtime is not as refined. Every call actually spawns a goroutine, which is pretty bad for such a small workload. This resulted in a 50% greater runtime. I also used an atomic variable rather than a channel, which makes sense in this case, although it's not idiomatic. I used a WaitGroup, as we don't know ahead of time how many goroutines will be spawned.

A more idiomatic approach would be to create a worker pool and then send them tasks instead of spawning goroutines. This would likely be a little more performant as well, as sending on a channel has likely as smaller overhead than spawning a goroutine with its own stack. They could still use the atomic variable instead of channels for results.

A more practical approach would be to limit the depth of parallelism. Spawn goroutines for the first few levels of the tree, then explore each branch with a single thread. This would probably be the best approach.

