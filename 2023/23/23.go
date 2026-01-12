package main

import (
	"aoc/2023/common"
	"bufio"
	"maps"
	"slices"
	"sync"
)

const side = 141

type node = [2]int

type edge struct {
	dst    node
	weight int
}

type graph = map[node][]edge

type void = struct{}

var directions = [...]struct {
	di, dj int
	char   byte
}{
	{0, -1, '<'},
	{0, +1, '>'},
	{-1, 0, '^'},
	{+1, 0, 'v'},
}

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  takeAHikeST,
		MT_Impl:  takeAHikeMT,
		Part1Str: "Not climbing slopes",
		Part2Str: "Slopes are fine",
	}
	common.Benchmark(thisProgram, 3)
}

func takeAHikeST() common.Results[int, int] {
	grid := makeGrid()
	start, end := findEnds(grid)
	G := findNodes(grid)
	G[node{0, start}] = make([]edge, 0, 1)
	G[node{side - 1, end}] = make([]edge, 0, 1)
	connectNodes(grid, G, start)

	var results common.Results[int, int]
	dfsST(node{0, start}, node{side - 1, end}, 0, &results.Part1, make(map[node]void), G)

	undirectEdges(G)
	dfsST(node{0, start}, node{side - 1, end}, 0, &results.Part2, make(map[node]void), G)

	return results
}

func takeAHikeMT() common.Results[int, int] {
	grid := makeGrid()
	start, end := findEnds(grid)
	G := findNodes(grid)
	G[node{0, start}] = make([]edge, 0, 1)
	G[node{side - 1, end}] = make([]edge, 0, 1)
	connectNodes(grid, G, start)

	var results common.Results[int, int]
	maxDepth := 10 // Experimentally, this was the best depth cutoff.
	dfsMT(node{0, start}, node{side - 1, end}, 0, &results.Part1, make(map[node]void), G, maxDepth)

	undirectEdges(G)
	dfsMT(node{0, start}, node{side - 1, end}, 0, &results.Part2, make(map[node]void), G, maxDepth)

	return results
}

func undirectEdges(G graph) {
	for v, E := range G {
		for _, e := range E {
			E := G[e.dst]
			if !slices.ContainsFunc(E, func(e edge) bool {
				return e.dst == v
			}) {
				E = append(E, edge{dst: v, weight: e.weight})
				G[e.dst] = E
			}
		}
	}
}

func dfsST(curr, end node, length int, result *int, visited map[node]void, G graph) {
	// Base case.
	if curr == end {
		*result = max(length, *result)
		return
	}
	// Recursive case.
	visited[curr] = void{}
	for _, e := range G[curr] {
		// Avoid cycles.
		if _, ok := visited[e.dst]; !ok {
			dfsST(e.dst, end, length+e.weight, result, visited, G)
		}
	}

	// Restore visited set for parent call.
	delete(visited, curr)
}

func dfsMT(curr, end node, length int, result *int, visited map[node]void, G graph, depthLeft int) {
	if depthLeft == 0 {
		dfsST(curr, end, length, result, visited, G)
	} else {
		if curr == end {
			*result = max(length, *result)
			return
		}
		visited[curr] = void{}
		var partialResults [4]int
		var wg sync.WaitGroup
		for i, e := range G[curr] {
			if _, ok := visited[e.dst]; !ok {
				wg.Go(func() {
					dfsMT(e.dst, end, length+e.weight, &partialResults[i], maps.Clone(visited), G, depthLeft-1)
				})
			}
		}
		wg.Wait()
		var partial int
		for _, r := range partialResults {
			partial = max(partial, r)
		}
		*result = partial
		delete(visited, curr)
	}
}

func connectNodes(grid [][side]byte, G graph, start int) {
	for v, e := range G {
		// Skip start and end for now.
		if v[0] == 0 || v[0] == side-1 {
			continue
		}
		// Explore paths in all directions.
		for _, d := range directions {
			prev := node{v[0] + d.di, v[1] + d.dj}
			// Respect directed edges.
			if grid[prev[0]][prev[1]] != d.char {
				continue
			}
			// Follow this path until it hits another node. Keep track of the length.
			curr := node{v[0] + 2*d.di, v[1] + 2*d.dj}
			for weight := 2; ; weight++ {
				// This path is over.
				if _, ok := G[curr]; ok {
					// Modify the slice copy. Must store it back.
					e = append(e, edge{curr, weight})
					break
				}
				// Go to next step in this path.
				for _, d := range directions {
					next := node{curr[0] + d.di, curr[1] + d.dj}
					// Never go backwards.
					if next == prev {
						continue
					}
					// There's a single cell we can go to.
					// No need for bounds check because of sentinel walls.
					if grid[next[0]][next[1]] != '#' {
						prev = curr
						curr = next
						break
					}
				}
			}
		}
		// Save slice back in the map.
		G[v] = e
	}
	// Connect start.
	src := node{0, start}
	e := G[src]
	for _, d := range directions {
		// There's a single path, so we break after this.
		if d.di != -1 && grid[src[0]+d.di][src[1]+d.dj] == '.' {
			prev := src
			curr := node{src[0] + d.di, src[1] + d.dj}
			for weight := 1; ; weight++ {
				if _, ok := G[curr]; ok {
					e = append(e, edge{curr, weight})
					break
				}
				for _, d := range directions {
					next := node{curr[0] + d.di, curr[1] + d.dj}
					if next == prev {
						continue
					}
					if grid[next[0]][next[1]] != '#' {
						prev = curr
						curr = next
						break
					}
				}
			}
			break
		}
	}
	G[src] = e
}

func findNodes(grid [][side]byte) graph {
	G := make(graph)
	for i := 1; i < side-1; i++ {
		for j := 1; j < side-1; j++ {
			if grid[i][j] == '.' {
				if d := degree(grid, i, j); d != 2 {
					G[node{i, j}] = make([]edge, 0, d)
				}
			}
		}
	}
	return G
}

func degree(grid [][side]byte, i, j int) int {
	var d int
	for _, dir := range directions {
		if grid[i+dir.di][j+dir.dj] != '#' {
			d += 1
		}
	}
	return d
}

func findEnds(grid [][side]byte) (start, end int) {
	for i := range side {
		if grid[0][i] == '.' {
			start = i
		}
		if grid[side-1][i] == '.' {
			end = i
		}
	}
	return
}

func makeGrid() [][side]byte {
	grid := make([][side]byte, side)

	file, closer := common.Open("input")
	defer closer()
	scanner := bufio.NewScanner(file)

	for i := 0; scanner.Scan(); i++ {
		line := scanner.Text()
		copy(grid[i][:], line)
	}

	return grid
}
