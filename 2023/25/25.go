package main

import (
	"aoc/2023/common"
	"bufio"
	"context"
	"math/rand"
	"runtime"
	"slices"
	"strings"
)

type graph = [][]int

type edge = [2]int

type unionFind struct {
	parents, sizes []int
	components     int
}

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  splitGraphST,
		MT_Impl:  splitGraphMT,
		Part1Str: "Componentes product",
		Part2Str: "nil",
	}
	common.Benchmark(thisProgram, 1000)
}

func splitGraphST() common.Results[int, int] {
	G, E := makeGraph()

	rng := rand.New(rand.NewSource(0))
	n := len(G)
	uf := unionFind{
		parents: make([]int, n),
		sizes:   make([]int, n),
	}

	for {
		if result := kargerMinCut(G, E, uf, rng); result != 0 {
			return common.Results[int, int]{Part1: result}
		}
	}
}

func splitGraphMT() common.Results[int, int] {
	G, E := makeGraph()

	numWorkers := runtime.GOMAXPROCS(0)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	resultChan := make(chan int, 1)

	for i := range numWorkers {
		go func() {
			rng := rand.New(rand.NewSource(int64(i)))
			ECopy := slices.Clone(E)
			n := len(G)
			uf := unionFind{
				parents: make([]int, n),
				sizes:   make([]int, n),
			}
			for {
				select {
				case <-ctx.Done():
					return
				default:
				}

				if result := kargerMinCut(G, ECopy, uf, rng); result != 0 {
					select {
					case resultChan <- result:
						return
					case <-ctx.Done():
						break
					}
				}
			}
		}()
	}

	return common.Results[int, int]{Part1: <-resultChan}
}

func kargerMinCut(G graph, E []edge, uf unionFind, rng *rand.Rand) int {
	n := len(G)
	// Init uf.
	uf.components = n
	for i := range n {
		uf.parents[i] = i
		uf.sizes[i] = 1
	}
	// Randomize E.
	rng.Shuffle(len(E), func(i, j int) {
		E[i], E[j] = E[j], E[i]
	})

	// Random contractions.
	for _, e := range E {
		uf.union(e[0], e[1])
		if uf.components == 2 {
			break
		}
	}

	// Correctness check.
	var cutEdges int
	for _, e := range E {
		if uf.find(e[0]) != uf.find(e[1]) {
			cutEdges++
		}
	}
	if cutEdges != 3 {
		return 0
	}

	var sizeA, sizeB int
	rootA := uf.find(0)
	for i := range n {
		if uf.find(i) == rootA {
			sizeA++
		} else {
			sizeB++
		}
	}
	return sizeA * sizeB
}

func (uf *unionFind) find(x int) int {
	root := uf.parents[x]
	if root == x {
		return x
	}
	uf.parents[x] = uf.find(root)
	return uf.parents[x]
}

func (uf *unionFind) union(p, q int) {
	a, b := uf.find(p), uf.find(q)
	if a != b {
		if uf.sizes[a] < uf.sizes[b] {
			uf.parents[a] = b
			uf.sizes[b] += uf.sizes[a]
		} else {
			uf.parents[b] = a
			uf.sizes[a] += uf.sizes[b]
		}
		uf.components--
	}
}

func makeGraph() (graph, []edge) {
	input, closer := common.Open("input")
	defer closer()

	E := make([]edge, 0, 3271)
	G := make(graph, 1460)
	scanner := bufio.NewScanner(input)
	strToInt := make(map[string]int, 1460)
	var count int
	for scanner.Scan() {
		line := scanner.Text()
		src := line[:3]
		var i, j int
		var ok bool
		if i, ok = strToInt[src]; !ok {
			strToInt[src] = count
			i = count
			count++
		}
		dsts := strings.Fields(line[5:])
		S := G[i]
		for _, d := range dsts {
			if j, ok = strToInt[d]; !ok {
				strToInt[d] = count
				j = count
				count++
			}
			E = append(E, edge{i, j})
			S = append(S, j)
			D := G[j]
			D = append(D, i)
			G[j] = D
		}
		G[i] = S
	}
	return G, E
}
