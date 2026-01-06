package main

import (
	"aoc/2023/common"
	"bufio"
	"runtime"
	"sort"
	"strings"
)

type p struct {
	x, y uint8
	z    uint16
}

type brick struct {
	low, high    p
	above, below []*brick
}

type projection struct {
	xs, xe, ys, ye uint8
}

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  disintegrateBrickST,
		MT_Impl:  disintegrateBrickMT,
		Part1Str: "Safely remove:",
		Part2Str: "Chain reactions sum:",
	}
	common.Benchmark(thisProgram, 10)
}

func disintegrateBrickST() common.Results[int, int] {
	bricks := readBricks()
	applyGravity(bricks)
	return solveSlice(bricks)
}

func disintegrateBrickMT() common.Results[int, int] {
	bricks := readBricks()
	// Must be sequential.
	applyGravity(bricks)
	var results common.Results[int, int]
	numWorkers := runtime.GOMAXPROCS(0)
	partialResults := make(chan common.Results[int, int], numWorkers)
	rangePerWorker := len(bricks) / numWorkers
	for i := range numWorkers {
		go func() {
			start := i * rangePerWorker
			end := start + rangePerWorker
			if i == numWorkers-1 {
				end = len(bricks)
			}
			partialResults <- solveSlice(bricks[start:end])
		}()
	}
	for range numWorkers {
		r := <-partialResults
		results.Part1 += r.Part1
		results.Part2 += r.Part2
	}
	close(partialResults)
	return results
}

// Drop bricks, starting with the lowest.
func applyGravity(bricks []*brick) {
	sort.Slice(bricks, func(i, j int) bool {
		return bricks[i].low.z < bricks[j].low.z
	})
	// Record highest height and lazily keep `dropped` sorted by `brick.high.z`.
	highest := uint16(1)
	dropped := make([]*brick, 0, len(bricks))
	for i, b := range bricks {
		collides := false
		thisProjection := makeProjection(b)
		// Check if previously dropped bricks collide, starting in reverse.
		for j := i - 1; j >= 0; j-- {
			d := dropped[j]
			// No more collisions possible.
			if collides && b.low.z > d.high.z+1 {
				break
			}
			thatProjection := makeProjection(d)
			if thisProjection.xs <= thatProjection.xe &&
				thatProjection.xs <= thisProjection.xe &&
				thisProjection.ys <= thatProjection.ye &&
				thatProjection.ys <= thisProjection.ye {
				// Append to `above` and `below`.
				collides = true
				drop := b.low.z - d.high.z - 1
				b.low.z -= drop
				b.high.z -= drop
				d.above = append(d.above, b)
				b.below = append(b.below, d)
			}
		}
		// No collisions. Drop low.z to 1, and keep high.z difference.
		if !collides {
			b.high.z -= b.low.z - 1
			b.low.z = 1
		}

		dropped = append(dropped, b)
		// Invariant: `dropped` is sorted by `brick.high.z`.
		if b.high.z < highest {
			// Insertion sort would be best with only 1 element out of order.
			sort.Slice(dropped, func(i, j int) bool {
				return dropped[i].high.z < dropped[j].high.z
			})
		} else {
			highest = b.high.z
		}
	}
}

func solveSlice(bricks []*brick) (results common.Results[int, int]) {
	q := common.MakeDeque[*brick](256)
	for _, b := range bricks {
		canRemove := true
		// If every brick above has at least 2 below, this can be removed.
		for _, a := range b.above {
			canRemove = canRemove && len(a.below) != 1
		}
		if canRemove {
			results.Part1++
		} else {
			q.PushBack(b)
			fallen := map[*brick]struct{}{b: {}}
			for next, ok := q.PopFront(); ok; next, ok = q.PopFront() {
				for _, child := range next.above {
					willFall := true
					for _, support := range child.below {
						_, ok := fallen[support]
						willFall = willFall && ok
					}
					if willFall {
						fallen[child] = struct{}{}
						q.PushBack(child)
					}
				}
			}
			results.Part2 += len(fallen) - 1
		}
	}
	return results
}

func makeProjection(b *brick) projection {
	return projection{
		xs: min(b.low.x, b.high.x),
		xe: max(b.low.x, b.high.x),
		ys: min(b.low.y, b.high.y),
		ye: max(b.low.y, b.high.y),
	}
}

func readBricks() []*brick {
	var bricks []*brick
	file, closer := common.Open("input")
	defer closer()
	scanner := bufio.NewScanner(file)

	for i := 0; scanner.Scan(); i++ {
		line := scanner.Text()
		ends := strings.Split(line, "~")
		start := strings.Split(ends[0], ",")
		end := strings.Split(ends[1], ",")
		p1 := p{
			uint8(common.Atoi(start[0])),
			uint8(common.Atoi(start[1])),
			uint16(common.Atoi(start[2])),
		}
		p2 := p{
			uint8(common.Atoi(end[0])),
			uint8(common.Atoi(end[1])),
			uint16(common.Atoi(end[2])),
		}
		if p1.z <= p2.z {
			bricks = append(bricks, &brick{low: p1, high: p2})
		} else {
			bricks = append(bricks, &brick{low: p2, high: p1})
		}
	}

	return bricks
}
