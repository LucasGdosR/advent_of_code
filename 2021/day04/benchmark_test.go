package day04

import (
	"aoc/internal/read"
	"testing"
)

var (
	blackhole int
	realInput = read.FileToBytes("testdata/input")
)

func BenchmarkPart1(b *testing.B) {
	numberToBoard := make([][]int, maxRandom)
	boardBackingSlice := make([]int, len(numberToBoard)*35)
	for i, j := 0, 0; i < len(numberToBoard); i, j = i+1, j+35 {
		numberToBoard[i] = boardBackingSlice[j : j : j+35]
	}
	boards := make([][boardsSize]byte, maxBoards)

	for b.Loop() {
		part1(realInput, numberToBoard, &boards)
	}
}

func BenchmarkPart2(b *testing.B) {
	numberToBoard := make([][]int, maxRandom)
	boardBackingSlice := make([]int, len(numberToBoard)*35)
	for i, j := 0, 0; i < len(numberToBoard); i, j = i+1, j+35 {
		numberToBoard[i] = boardBackingSlice[j : j : j+35]
	}
	boards := make([][boardsSize]byte, maxBoards)

	for b.Loop() {
		part2(realInput, numberToBoard, &boards)
	}
}
