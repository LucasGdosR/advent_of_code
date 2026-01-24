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
	var X, Y int
	for i := 0; i < len(input); {
		switch input[i] {
		case 'f':
			X += int(input[i+8]) - '0'
			i += 10
		case 'd':
			Y += int(input[i+5]) - '0'
			i += 7
		case 'u':
			Y -= int(input[i+3]) - '0'
			i += 5
		}
	}
	return X, Y
}

func Part2(input []byte) int {
	X, Y := part2(input)
	return X * Y
}

func part2(input []byte) (int, int) {
	var X, Y, aim int
	for i := 0; i < len(input); {
		switch input[i] {
		case 'f':
			v := int(input[i+8]) - '0'
			X += v
			Y += v * aim
			i += 10
		case 'd':
			aim += int(input[i+5]) - '0'
			i += 7
		case 'u':
			aim -= int(input[i+3]) - '0'
			i += 5
		}
	}
	return X, Y
}
