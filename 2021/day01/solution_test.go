package day01

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
	expected := 7
	if got := Part1(input); got != expected {
		t.Errorf("Part1(example): expected %v, got %v", expected, got)
	}
}

func TestPart2Example(t *testing.T) {
	t.Parallel()
	expected := 5
	if got := Part2(input); got != expected {
		t.Errorf("Part2(example): expected %v, got %v", expected, got)
	}
}

func TestEdgeCases(t *testing.T) {
	tests := []struct {
		name  string
		input []byte
		p1    int
		p2    int
	}{
		{"empty", []byte(""), 0, 0},
		{"single", []byte("42"), 0, 0},
		{"two", []byte("1\n2"), 1, 0},
		{"three", []byte("1\n2\n3"), 2, 0},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()
			if got := Part1(tc.input); got != tc.p1 {
				t.Errorf("Part1(%v): expected %v, got %v", tc.name, tc.p1, got)
			}
			if got := Part2(tc.input); got != tc.p2 {
				t.Errorf("Part2(%v): expected %v, got %v", tc.name, tc.p2, got)
			}
		})
	}
}
