package day02

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
	expectedX, expectedY := 15, 10
	if gotX, gotY := part1(input); gotX != expectedX || gotY != expectedY {
		t.Errorf("Part1(example): expectedX %v, gotX %v, expectedY %v, gotY%v", expectedX, gotX, expectedY, gotY)
	}
}

func TestPart2Example(t *testing.T) {
	t.Parallel()
	expectedX, expectedY := 15, 60
	if gotX, gotY := part2(input); gotX != expectedX || gotY != expectedY {
		t.Errorf("Part2(example): expectedX %v, gotX %v, expectedY %v, gotY%v", expectedX, gotX, expectedY, gotY)
	}
}
