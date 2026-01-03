package main

import (
	"aoc/2023/common"
	"bufio"
	"container/heap"
)

const (
	up = iota
	right
	down
	left
	side = 141
)

type key struct {
	i, j, dir, steps uint8
}
type state struct {
	d int
	key
}
type minHeap []state

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  driveCrucibleST,
		MT_Impl:  driveCrucibleMT,
		Part1Str: "Large crucible minimum heat loss",
		Part2Str: "Ultra crucible minimum heat loss",
	}
	common.Benchmark(thisProgram, 10)
}

func driveCrucibleST() common.Results[int, int] {
	grid := makeGrid()
	var results common.Results[int, int]
	results.Part1 = shortestPath(grid, getNeighborsPart1)
	results.Part2 = shortestPath(grid, getNeighborsPart2)
	return results
}

func driveCrucibleMT() common.Results[int, int] {
	grid := makeGrid()
	var results common.Results[int, int]
	p1 := make(chan int)
	p2 := make(chan int)
	go func() {
		p1 <- shortestPath(grid, getNeighborsPart1)
	}()
	go func() {
		p2 <- shortestPath(grid, getNeighborsPart2)
	}()
	results.Part1 = <-p1
	close(p1)
	results.Part2 = <-p2
	close(p2)
	return results
}

func shortestPath(grid [][side]byte, getNeighbors func(state, [][side]byte) []state) int {
	distances := map[key]int{
		{dir: down}:  0,
		{dir: right}: 0,
	}
	h := &minHeap{}
	heap.Push(h, state{key: key{dir: down}})
	heap.Push(h, state{key: key{dir: right}})
	for {
		// In Dijkstra / A*, we must check the destination after popping from the heap,
		// and not before pushing onto it.
		element := heap.Pop(h)
		e := element.(state)
		if d, ok := distances[e.key]; ok && d < e.d {
			continue
		}

		if e.i == side-1 && e.j == side-1 {
			return e.d
		}

		neighbors := getNeighbors(e, grid)
		for _, n := range neighbors {
			if d, ok := distances[n.key]; !ok || d > n.d {
				distances[n.key] = n.d
				heap.Push(h, state{d: n.d, key: n.key})
			}
		}
	}
}

func getNeighborsPart1(s state, grid [][side]byte) []state {
	var neighbors []state
	if s.steps < 3 {
		if n, ok := advanceByOne(s, grid); ok {
			neighbors = append(neighbors, n)
		}
	}
	s.steps = 0
	// Turn right.
	s.dir = (s.dir + 1) % 4
	if n, ok := advanceByOne(s, grid); ok {
		neighbors = append(neighbors, n)
	}
	// Turn left.
	s.dir = (s.dir - 2) % 4
	if n, ok := advanceByOne(s, grid); ok {
		neighbors = append(neighbors, n)
	}
	return neighbors
}

func getNeighborsPart2(s state, grid [][side]byte) []state {
	var neighbors []state
	// Edge case for starting states.
	if s.steps == 0 {
		if n, ok := advanceByFour(s, grid); ok {
			neighbors = append(neighbors, n)
		}
	} else if s.steps < 10 {
		if n, ok := advanceByOne(s, grid); ok {
			neighbors = append(neighbors, n)
		}
	}
	s.steps = 0
	// Turn right.
	s.dir = (s.dir + 1) % 4
	if n, ok := advanceByFour(s, grid); ok {
		neighbors = append(neighbors, n)
	}
	// Turn left.
	s.dir = (s.dir - 2) % 4
	if n, ok := advanceByFour(s, grid); ok {
		neighbors = append(neighbors, n)
	}
	return neighbors
}

func advanceByOne(s state, grid [][side]byte) (next state, ok bool) {
	switch s.dir {
	case up:
		if s.i == 0 {
			return
		}
		s.i--
	case down:
		if s.i == side-1 {
			return
		}
		s.i++
	case right:
		if s.j == side-1 {
			return
		}
		s.j++
	case left:
		if s.j == 0 {
			return
		}
		s.j--
	}
	s.steps += 1
	s.d += int(grid[s.i][s.j] - '0')
	return s, true
}

func advanceByFour(s state, grid [][side]byte) (next state, ok bool) {
	for range 4 {
		if s, ok = advanceByOne(s, grid); !ok {
			return
		}
	}
	return s, true
}

func (h minHeap) Len() int      { return len(h) }
func (h minHeap) Swap(i, j int) { h[i], h[j] = h[j], h[i] }
func (h *minHeap) Push(x any)   { *h = append(*h, x.(state)) }

// A* heuristic: manhattan distance to the exit
func (h minHeap) Less(i, j int) bool {
	ei, ej := h[i], h[j]
	return ei.d-int(ei.i+ei.j) < ej.d-int(ej.i+ej.j)
}

func (h *minHeap) Pop() any {
	old := *h
	n := len(old)
	x := old[n-1]
	*h = old[:n-1]
	return x
}

func makeGrid() [][side]byte {
	grid := make([][side]byte, side)

	file := common.Open("input")
	scanner := bufio.NewScanner(file)

	for i := 0; scanner.Scan(); i++ {
		line := scanner.Text()
		copy(grid[i][:], line)
	}

	return grid
}
