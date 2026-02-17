package day04

import (
	"aoc/internal/read"
	"os"
	"testing"
)

var input []byte

func TestMain(m *testing.M) {
	input = read.FileToBytes("testdata/example")
	os.Exit(m.Run())
}

func TestPart1Example(t *testing.T) {
	t.Parallel()
	expectedUnmarked, expectedLast := 188, 24

	numberToBoard := make([][]int, maxRandom)
	boardBackingSlice := make([]int, len(numberToBoard)*35)
	for i, j := 0, 0; i < len(numberToBoard); i, j = i+1, j+35 {
		numberToBoard[i] = boardBackingSlice[j : j : j+35]
	}
	boards := make([][boardSize + rows + cols + cache]byte, maxBoards)

	if gotUnmarked, gotLast := part1(input, numberToBoard, &boards); gotUnmarked != expectedUnmarked || gotLast != expectedLast {
		t.Errorf("Part1(example): expectedUnmarked %v, gotUnmarked %v, expectedLast %v, gotLast%v", expectedUnmarked, gotUnmarked, expectedLast, gotLast)
	}
}

func TestPart2Example(t *testing.T) {
	t.Parallel()
	expectedUnmarked, expectedLast := 148, 13

	numberToBoard := make([][]int, maxRandom)
	boardBackingSlice := make([]int, len(numberToBoard)*35)
	for i, j := 0, 0; i < len(numberToBoard); i, j = i+1, j+35 {
		numberToBoard[i] = boardBackingSlice[j : j : j+35]
	}
	boards := make([][boardSize + rows + cols + cache]byte, maxBoards)

	if gotUnmarked, gotLast := part2(input, numberToBoard, &boards); gotUnmarked != expectedUnmarked || gotLast != expectedLast {
		t.Errorf("Part2(example): expectedUnmarked %v, gotUnmarked %v, expectedLast %v, gotLast%v", expectedUnmarked, gotUnmarked, expectedLast, gotLast)
	}
}
