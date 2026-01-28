package day03

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
	expectedGamma, expectedEpsilon := 22, 9
	if gotGamma, gotEpsilon := part1(input); gotGamma != expectedGamma || gotEpsilon != expectedEpsilon {
		t.Errorf("Part1(example): expectedGamma %v, gotGamma %v, expectedEpsilon %v, gotEpsilon%v", expectedGamma, gotGamma, expectedEpsilon, gotEpsilon)
	}
}

func TestPart2Example(t *testing.T) {
	t.Parallel()
	expectedO, expectedC := 23, 10
	if gotO, gotC := part2(input); gotO != expectedO || gotC != expectedC {
		t.Errorf("Part2(example): expectedO %v, gotO %v, expectedC %v, gotC%v", expectedO, gotO, expectedC, gotC)
	}
}
