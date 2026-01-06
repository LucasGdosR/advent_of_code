package main

import (
	"aoc/2023/common"
	"bufio"
	"math"
)

const (
	side      = 131
	n         = uint64((26501365 - side/2) / side)
	oddTiles  = (n + 1) * (n + 1)
	evenTiles = n * n
)

var directions = [4][2]int{
	{0, 1}, {0, -1}, {1, 0}, {-1, 0},
}

func main() {
	grid := makeGrid()

	q := common.MakeDeque[[2]int](256)
	start := [2]int{65, 65}
	q.PushBack(start)
	evensCenter, oddsCenter := bfs(q, grid, 65)

	odds65Adjustment := q.Len()
	oddCorners, evenCorners := bfs(q, grid, math.MaxInt)
	oddsCenter += odds65Adjustment
	oddCorners -= odds65Adjustment

	results := common.Results[uint64, uint64]{
		Part1: evensCenter,
		Part2: oddTiles*(oddCorners+oddsCenter) + evenTiles*(evenCorners+evensCenter) - (n+1)*oddCorners + n*evenCorners,
	}
	println("Part 1:", results.Part1, "\nPart 2:", results.Part2)
}

func bfs(q *common.Deque[[2]int], grid [][side]byte, end int) (evens, odds uint64) {
	for i := range end {
		level := q.Len()
		if level == 0 {
			break
		}
		if i%2 == 0 {
			evens += level
		} else {
			odds += level
		}
		for range level {
			next, _ := q.PopFront()
			for _, d := range directions {
				n := next
				n[0] += d[0]
				n[1] += d[1]
				if n[0] >= 0 && n[0] < side &&
					n[1] >= 0 && n[1] < side &&
					grid[n[0]][n[1]]&1 == 0 {
					grid[n[0]][n[1]] |= 1
					q.PushBack(n)
				}
			}
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
