package main

import (
	"aoc/2023/common"
	"bufio"
	"strings"
	"sync"
	"sync/atomic"
)

type category int

const (
	x category = iota
	m
	a
	s
)

type test struct {
	xmas   category
	lt     bool
	target int
	dst    string
}
type workflow struct {
	tests     []test
	otherwise string
}

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  findAcceptingRatingsST,
		MT_Impl:  findAcceptingRatingsMT,
		Part1Str: "Accepted parts sum",
		Part2Str: "Accepted ratings combinations",
	}
	common.Benchmark(thisProgram, 1000)
}

func findAcceptingRatingsST() common.Results[int, int] {
	input, closer := common.Open("input")
	defer closer()

	var results common.Results[int, int]
	scanner := bufio.NewScanner(input)
	workflows := makeWorkflows(scanner)

	for scanner.Scan() {
		line := scanner.Text()
		part := strings.Split(line, ",")
		r := [...]int{
			common.Atoi(part[0][3:]),
			common.Atoi(part[1][2:]),
			common.Atoi(part[2][2:]),
			common.Atoi(part[3][2 : len(part[3])-1]),
		}
		if accept(r, workflows) {
			results.Part1 += r[0] + r[1] + r[2] + r[3]
		}
	}

	results.Part2 = dfs(workflows, "in", [8]int{
		1, 4000, 1, 4000, 1, 4000, 1, 4000,
	})

	return results
}

func dfs(W map[string]workflow, key string, intervals [8]int) int {
	switch key[0] {
	case 'A':
		return max(0, intervals[1]-intervals[0]+1) *
			max(0, intervals[3]-intervals[2]+1) *
			max(0, intervals[5]-intervals[4]+1) *
			max(0, intervals[7]-intervals[6]+1)
	case 'R':
		return 0
	default:
		wf := W[key]
		var results int
		for _, t := range wf.tests {
			if t.lt {
				// Make one path where the comparison succeeds
				i := t.xmas*2 + 1
				temp := intervals[i]
				intervals[i] = min(temp, t.target-1)
				results += dfs(W, t.dst, intervals)
				// and adjust the interval for all others.
				intervals[i] = temp
				intervals[i-1] = max(intervals[i-1], t.target)
			} else {
				// Make one path where the comparison succeeds
				i := t.xmas * 2
				temp := intervals[i]
				intervals[i] = max(temp, t.target+1)
				results += dfs(W, t.dst, intervals)
				// and adjust the interval for all others.
				intervals[i] = temp
				intervals[i+1] = min(intervals[i+1], t.target)
			}
		}
		return results + dfs(W, wf.otherwise, intervals)
	}
}

func findAcceptingRatingsMT() common.Results[int, int] {
	input, closer := common.Open("input")
	defer closer()

	var results common.Results[int, int]
	scanner := bufio.NewScanner(input)
	workflows := makeWorkflows(scanner)

	var wg sync.WaitGroup
	wg.Go(func() {
		for scanner.Scan() {
			line := scanner.Text()
			part := strings.Split(line, ",")
			r := [...]int{
				common.Atoi(part[0][3:]),
				common.Atoi(part[1][2:]),
				common.Atoi(part[2][2:]),
				common.Atoi(part[3][2 : len(part[3])-1]),
			}
			if accept(r, workflows) {
				results.Part1 += r[0] + r[1] + r[2] + r[3]
			}
		}
	})

	var r2 atomic.Int64
	wg.Go(func() {
		dfsMT(workflows, "in", [8]int{
			1, 4000, 1, 4000, 1, 4000, 1, 4000,
		}, &wg, &r2)
	})
	wg.Wait()
	results.Part2 = int(r2.Load())
	return results
}

func dfsMT(W map[string]workflow, key string, intervals [8]int, wg *sync.WaitGroup, a *atomic.Int64) {
	switch key[0] {
	case 'A':
		a.Add(int64(max(0, intervals[1]-intervals[0]+1) *
			max(0, intervals[3]-intervals[2]+1) *
			max(0, intervals[5]-intervals[4]+1) *
			max(0, intervals[7]-intervals[6]+1),
		))
	case 'R':
	default:
		wf := W[key]
		for _, t := range wf.tests {
			if t.lt {
				// Make one path where the comparison succeeds
				i := t.xmas*2 + 1
				intervalsCopy := intervals
				intervalsCopy[i] = min(intervalsCopy[i], t.target-1)
				wg.Go(func() { dfsMT(W, t.dst, intervalsCopy, wg, a) })
				// and adjust the interval for all others.
				intervals[i-1] = max(intervals[i-1], t.target)
			} else {
				// Make one path where the comparison succeeds
				i := t.xmas * 2
				intervalsCopy := intervals
				intervalsCopy[i] = max(intervalsCopy[i], t.target+1)
				wg.Go(func() { dfsMT(W, t.dst, intervalsCopy, wg, a) })
				// and adjust the interval for all others.
				intervals[i+1] = min(intervals[i+1], t.target)
			}
		}
		dfsMT(W, wf.otherwise, intervals, wg, a)
	}
}

func makeWorkflows(scanner *bufio.Scanner) map[string]workflow {
	workflows := make(map[string]workflow, 528)
	for {
		scanner.Scan()
		line := scanner.Text()
		if len(line) == 0 {
			break
		}
		i := strings.IndexByte(line, '{')
		key := line[:i]
		branches := strings.Split(line[i+1:len(line)-1], ",")
		wf := workflow{
			make([]test, 0, len(branches)-1),
			branches[len(branches)-1],
		}
		for _, branch := range branches[:len(branches)-1] {
			var t test
			switch branch[0] {
			case 'x':
				t.xmas = x
			case 'm':
				t.xmas = m
			case 'a':
				t.xmas = a
			case 's':
				t.xmas = s
			}
			t.lt = branch[1] == '<'
			i := strings.IndexByte(branch, ':')
			t.target = common.Atoi(branch[2:i])
			t.dst = branch[i+1:]
			wf.tests = append(wf.tests, t)
		}
		workflows[key] = wf
	}
	return workflows
}

func accept(r [4]int, w map[string]workflow) bool {
	key := "in"
outer:
	for {
		switch key[0] {
		case 'A':
			return true
		case 'R':
			return false
		default:
			wf := w[key]
			for _, t := range wf.tests {
				if cmp(r[t.xmas], t.target, t.lt) {
					key = t.dst
					continue outer
				}
			}
			key = wf.otherwise
		}
	}
}

func cmp(n, target int, lt bool) bool {
	if lt {
		return n < target
	} else {
		return n > target
	}
}
