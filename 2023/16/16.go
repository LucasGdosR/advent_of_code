package main

import (
	"aoc/2023/common"
	"bufio"
	"runtime"
)

type state struct {
	i, j, dir int8
}

const (
	UP = 1 << iota
	RIGHT
	DOWN
	LEFT
	LENGTH = 110
)

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  findMaxEnergizedST,
		MT_Impl:  findMaxEnergizedMT,
		Part1Str: "Energized from [0, -1, RIGHT]",
		Part2Str: "Energized max",
	}
	common.Benchmark(thisProgram, 100)
}

func findMaxEnergizedST() common.Results[int, int] {
	var results common.Results[int, int]
	grid := initGrid()
	var energized [LENGTH][LENGTH]int8
	results.Part1 = solve(state{i: 0, j: -1, dir: RIGHT}, &energized, grid)
	var maxEnergized int
	for i := range int8(LENGTH) {
		maxEnergized = max(maxEnergized,
			solve(state{i: -1, j: i, dir: DOWN}, &energized, grid),
			solve(state{i: LENGTH, j: i, dir: UP}, &energized, grid),
			solve(state{i: i, j: -1, dir: RIGHT}, &energized, grid),
			solve(state{i: i, j: LENGTH, dir: LEFT}, &energized, grid),
		)
	}
	results.Part2 = maxEnergized
	return results
}

func findMaxEnergizedMT() common.Results[int, int] {
	var results common.Results[int, int]
	grid := initGrid()
	numWorkers := int8(runtime.GOMAXPROCS(0))
	linesPerWorker := LENGTH / numWorkers
	partialResults := make(chan int, numWorkers)
	for i := range numWorkers {
		go func(i int8) {
			var energized [LENGTH][LENGTH]int8
			var maxEnergized int
			start := i * linesPerWorker
			end := start + linesPerWorker
			if i == numWorkers-1 {
				end = LENGTH
			}
			for i := start; i < end; i++ {
				maxEnergized = max(maxEnergized,
					solve(state{i: -1, j: i, dir: DOWN}, &energized, grid),
					solve(state{i: LENGTH, j: i, dir: UP}, &energized, grid),
					solve(state{i: i, j: -1, dir: RIGHT}, &energized, grid),
					solve(state{i: i, j: LENGTH, dir: LEFT}, &energized, grid),
				)
			}
			partialResults <- maxEnergized
		}(i)
	}
	var energized [LENGTH][LENGTH]int8
	results.Part1 = solve(state{i: 0, j: -1, dir: RIGHT}, &energized, grid)
	for range numWorkers {
		results.Part2 = max(results.Part2, <-partialResults)
	}
	close(partialResults)
	return results
}

func solve(start state, energized *[LENGTH][LENGTH]int8, grid [][]byte) int {
	defer func() { *energized = [LENGTH][LENGTH]int8{} }()

	propagateBeam(start, energized, grid)

	var count int
	for _, row := range energized {
		for _, cell := range row {
			if cell != 0 {
				count++
			}
		}
	}
	return count
}

func propagateBeam(s state, energized *[LENGTH][LENGTH]int8, grid [][]byte) {
	next := getNextTile(s)
	if next.i < 0 || next.i == LENGTH || next.j < 0 || next.j == LENGTH {
		return
	}
	if energized[next.i][next.j]&next.dir != 0 {
		return
	}

	energized[next.i][next.j] |= next.dir

	switch grid[next.i][next.j] {
	case '.':
		propagateBeam(next, energized, grid)
	case '\\':
		switch next.dir {
		case UP, LEFT:
			next.dir ^= UP ^ LEFT
		case DOWN, RIGHT:
			next.dir ^= DOWN ^ RIGHT
		}
		propagateBeam(next, energized, grid)
	case '/':
		switch next.dir {
		case UP, RIGHT:
			next.dir ^= UP ^ RIGHT
		case DOWN, LEFT:
			next.dir ^= DOWN ^ LEFT
		}
		propagateBeam(next, energized, grid)
	case '-':
		switch next.dir {
		case LEFT, RIGHT:
			propagateBeam(next, energized, grid)
		case UP, DOWN:
			next.dir = LEFT
			propagateBeam(next, energized, grid)
			next.dir = RIGHT
			propagateBeam(next, energized, grid)
		}
	case '|':
		switch next.dir {
		case UP, DOWN:
			propagateBeam(next, energized, grid)
		case LEFT, RIGHT:
			next.dir = UP
			propagateBeam(next, energized, grid)
			next.dir = DOWN
			propagateBeam(next, energized, grid)
		}
	}
}

func getNextTile(s state) state {
	switch s.dir {
	case UP:
		s.i--
	case RIGHT:
		s.j++
	case DOWN:
		s.i++
	case LEFT:
		s.j--
	}
	return s
}

func initGrid() [][]byte {
	grid := make([][]byte, LENGTH)
	// TODO: replace this for loop with slicing a single fixed array.
	for i := range grid {
		grid[i] = make([]byte, LENGTH)
	}

	file, closer := common.Open("input")
	defer closer()
	scanner := bufio.NewScanner(file)

	for i := 0; scanner.Scan(); i++ {
		line := scanner.Text()
		copy(grid[i], line)
	}

	return grid
}
