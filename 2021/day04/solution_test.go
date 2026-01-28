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
	if gotUnmarked, gotLast := part1(input); gotUnmarked != expectedUnmarked || gotLast != expectedLast {
		t.Errorf("Part1(example): expectedUnmarked %v, gotUnmarked %v, expectedLast %v, gotLast%v", expectedUnmarked, gotUnmarked, expectedLast, gotLast)
	}
}

func TestPart2Example(t *testing.T) {
	t.Parallel()
	expectedUnmarked, expectedLast := 148, 13
	if gotUnmarked, gotLast := part2(input); gotUnmarked != expectedUnmarked || gotLast != expectedLast {
		t.Errorf("Part2(example): expectedUnmarked %v, gotUnmarked %v, expectedLast %v, gotLast%v", expectedUnmarked, gotUnmarked, expectedLast, gotLast)
	}
}
