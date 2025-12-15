# Advent of Code of 2022

For this year, my personal challenges are to solve it in Odin and create visualizations.

I have an extra challenge of thinking of how to solve the problem with a multi-threaded solution. In general, I only propose how it could be multi-threaded, but there may be some multi-threaded solutions and visualizations. In hindsight, this particular Advent of Code edition does not seem to favor multithreading, as many problems have a sequential nature. I had many more opportunities to multithread in the 2023 edition.

- [x] 01: multi-threaded
- [x] 02: single-threaded; multi-threaded solution idea: parallelize the `for-loop`, each thread accumulates to local variables, and sum accumulated solutions.
- [x] 03: single-threaded; multi-threading: in theory, every set of three lines is indepedent. In practice, with varying lengths, finding sets requires reading them. Might as well solve them. Multi-threading not recommended.
- [x] 04: single-threaded; multi-threaded solution idea: chunk the input roughly, then adjust chunk boundaries to match line breaks. Proccess chunks independently, then sum accumulated solutions.
- [x] 05: single-threaded; multi-threading: this problem is serial, as it deals with stacks. It cannot be solved with multi-threading, except that part 1 and part 2 can be solved in parallel (so 2 threads max).
- [x] 06: single-threaded; multi-threaded solution idea: chunk the input and make chunks overlap so every substring is examinated by one thread. Get the solution index from the thread with the chunk with lowest starting index.
- [x] 07: single-threaded; multi-threading: this problem deals with trees, which are just stacks over time. The first pass, which builds the tree, is therefore serial. With the tree built, the second pass using DFS can be made in parallel, with different threads recursively exploring different branches of the tree. It's trivial with a multi-threading runtime (such as OpenCilk), but tricky with a from scratch solution.
- [x] 08: single-threaded; multi-threaded solution idea: the loops can be done in parallel as long as they don't try to write to the same index in the grid. This is trivial for part 2, which is read-only.
- [x] 09: single-threaded; multi-threading: this problem is serial. It cannot use multi-threading at all, I think.
- [x] 10: single-threaded; multi-threading: this problem is about mutating state serially. It cannot use multi-threading at all.
- [x] 11: single-threaded; multi-threading: all monkeys must be processed sequentially, but each element in each monkey can be processed in parallel. However, the processing step is short, and it must then mutate a shared data structure. Locking and unlocking would completely kill performance. I can't think of a good way to multithread this.
- [X] 12: single-threaded; multi-threading: one could run a BFS from every starting point at once, but it's much more elegant to run just a single BFS with all starting nodes in the starting queue.
- [X] 13: single-threaded; multi-threading solution idea: the file can be split in chunks and a boundary between two packets comparisons can be found by scanning for a '\n\n' sequence. Each thread can process chunks independently.
- [X] 14: single-threaded; this is a stack problem, so it's not really fit for multi-threading.
- [X] 15: single-threaded; multi-threaded solution idea: when looping through all lines looking for intercepts, this can be done in parallel.
- [ ] 16
- [ ] 17
- [ ] 18
- [ ] 19
- [ ] 20
- [ ] 21
- [ ] 22
- [ ] 23
- [ ] 24
- [ ] 25
