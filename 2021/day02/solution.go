package day02

import (
	"aoc/internal/registry"
)

func init() {
	registry.Register(2, 1, Part1)
	registry.Register(2, 2, Part2)
}

func Part1(input []byte) int {
	X, Y := part1(input)
	return X * Y
}

func part1(input []byte) (int, int) {
	var X, Y, dx, dy int
	for i := 0; i < len(input); {
		c := input[i]
		// Faster than switch
		if c == 'f' {
			X += int(input[i+8])
			dx++
			i += 10
		} else if c == 'd' {
			Y += int(input[i+5])
			dy++
			i += 7
		} else {
			Y -= int(input[i+3])
			dy--
			i += 5
		}
	}
	return X - dx*'0', Y - dy*'0'
}

func Part2(input []byte) int {
	X, Y := part2(input)
	return X * Y
}

func part2(input []byte) (int, int) {
	var X, Y, aim int
	for i := 0; i < len(input); {
		c := input[i]
		if c == 'f' {
			v := int(input[i+8]) - '0'
			X += v
			Y += v * aim
			i += 10
		} else if c == 'd' {
			aim += int(input[i+5]) - '0'
			i += 7
		} else {
			aim -= int(input[i+3]) - '0'
			i += 5
		}
	}
	return X, Y
}
