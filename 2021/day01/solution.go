package day01

import (
	"math"

	"aoc/internal/registry"
)

func init() {
	registry.Register(1, 1, Part1)
	registry.Register(1, 2, Part2)
}

func Part1(input []byte) int {
	var curr, result int
	prev := math.MaxInt
	for _, b := range input {
		if b == '\n' {
			if curr > prev {
				result++
			}
			prev = curr
		} else {
			curr = curr*10 + int(b-'0')
		}
	}
	if curr > prev {
		result++
	}
	return result
}

func Part2(input []byte) int {
	prev := [3]int{math.MaxInt, math.MaxInt, math.MaxInt}
	var i, curr, result int
	for _, b := range input {
		if b == '\n' {
			if curr > prev[i] {
				result++
			}
			prev[i] = curr
			i++
			// This is faster than %.
			if i == 3 {
				i = 0
			}
		} else {
			curr = curr*10 + int(b-'0')
		}
	}
	if curr > prev[i] {
		result++
	}
	return result
}
