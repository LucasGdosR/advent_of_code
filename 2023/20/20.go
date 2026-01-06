package main

import (
	"aoc/2023/common"
	"bufio"
	"strings"
)

type moduleKind uint8

const (
	broadcaster moduleKind = iota
	flipFlop
	conjunction
)

type module struct {
	kind          moduleKind
	state         bool
	upstreamState map[string]bool
	downstream    []string
}

type signal struct {
	pulse bool
	src   string
	dst   string
}

func main() {
	modules := makeModules()
	rxWriters := findRXWriters(modules)
	q := common.MakeDeque[signal](16)
	var results common.Results[int, int]
	var high int
	// Add 1000 button presses and broadcasts.
	low := 1000 * (1 + len(modules["broadcaster"].downstream))
	for button, count := 1, 0; count < 4; button++ {
		for _, dst := range modules["broadcaster"].downstream {
			q.PushBack(signal{src: "broadcaster", dst: dst})
		}
		for sig, ok := q.PopFront(); ok; sig, ok = q.PopFront() {
			dst := modules[sig.dst]
			if dst.kind == flipFlop && sig.pulse {
				continue
			}
			newSig := signal{src: sig.dst, pulse: !dst.state}
			if dst.kind == flipFlop {
				dst.state = !dst.state
			} else { // conjunction
				dst.upstreamState[sig.src] = sig.pulse
				allHigh := true
				for _, pulse := range dst.upstreamState {
					allHigh = allHigh && pulse
				}
				newSig.pulse = !allHigh
				if newSig.pulse {
					if _, ok := rxWriters[sig.dst]; ok {
						rxWriters[sig.dst] = button
						count++
					}
				}
			}
			for _, d := range dst.downstream {
				newSig.dst = d
				q.PushBack(newSig)
			}
			if newSig.pulse {
				high += len(dst.downstream)
			} else {
				low += len(dst.downstream)
			}
			modules[sig.dst] = dst
		}
		if button == 1000 {
			results.Part1 = high * low
		}
	}
	results.Part2 = 1
	for _, v := range rxWriters {
		results.Part2 *= v
	}
	println(results.Part1, results.Part2)
}

func findRXWriters(m map[string]module) map[string]int {
	var actualTarget string
	for k := range m["rx"].upstreamState {
		actualTarget = k
	}
	targetingTarget := make(map[string]int, 4)
	for k := range m[actualTarget].upstreamState {
		targetingTarget[k] = 0
	}
	return targetingTarget
}

func makeModules() map[string]module {
	input, closer := common.Open("input")
	defer closer()

	scanner := bufio.NewScanner(input)
	modules := make(map[string]module)
	for scanner.Scan() {
		line := scanner.Text()
		var m module
		key := line[1:3]
		downstream := line[7:]
		switch line[0] {
		case '%':
			m.kind = flipFlop
		case '&':
			m.kind = conjunction
			m.upstreamState = make(map[string]bool)
		default:
			m.kind = broadcaster
			key = "broadcaster"
			downstream = line[15:]
		}
		for d := range strings.SplitSeq(downstream, ", ") {
			m.downstream = append(m.downstream, d)
		}
		modules[key] = m
	}
	modules["rx"] = module{kind: conjunction, upstreamState: make(map[string]bool)}

	for k, v := range modules {
		for _, m := range v.downstream {
			if modules[m].kind == conjunction {
				modules[m].upstreamState[k] = false
			}
		}
	}

	return modules
}
