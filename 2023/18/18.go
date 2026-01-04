package main

import (
	"aoc/2023/common"
	"bufio"
	"math"
	"strconv"
	"strings"
)

type p struct {
	x, y int
}

func main() {
	diggerDirections, closer := common.Open("input")
	defer closer()

	var curr1, curr2 p
	var results common.Results[int, int]
	var perimeter1, perimeter2 int

	scanner := bufio.NewScanner(diggerDirections)
	for scanner.Scan() {
		line := scanner.Text()
		fs := strings.Fields(line)

		direction1 := fs[0][0]
		distance1 := common.Atoi(fs[1])
		next1 := curr1
		switch direction1 {
		case 'R':
			next1.x += distance1
		case 'D':
			next1.y -= distance1
		case 'L':
			next1.x -= distance1
		case 'U':
			next1.y += distance1
		}
		// Shoelace Formula.
		results.Part1 += (curr1.x * next1.y) - (curr1.y * next1.x)
		perimeter1 += distance1
		curr1 = next1

		color := fs[2]
		direction2 := color[7]
		distance2, _ := strconv.ParseInt(color[2:7], 16, 64)
		next2 := curr2
		switch direction2 {
		case '0':
			next2.x += int(distance2)
		case '1':
			next2.y -= int(distance2)
		case '2':
			next2.x -= int(distance2)
		case '3':
			next2.y += int(distance2)
		}
		results.Part2 += (curr2.x * next2.y) - (curr2.y * next2.x)
		perimeter2 += int(distance2)
		curr2 = next2
	}
	// The Shoelace Formula repeats the first point, but our first point is (0, 0), and 0 * n == 0.
	println((int(math.Abs(float64(results.Part1))) + perimeter1 + 2) / 2)
	println((int(math.Abs(float64(results.Part2))) + perimeter2 + 2) / 2)
}
