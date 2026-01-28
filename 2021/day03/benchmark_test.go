package day03

import (
	"aoc/internal/read"
	"testing"
)

var (
	blackhole int
	realInput = read.FileToBytes("testdata/input")
)

func BenchmarkPart1(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		blackhole = Part1(realInput)
	}
}

func BenchmarkPart2(b *testing.B) {
	b.ReportAllocs()
	for b.Loop() {
		blackhole = Part2(realInput)
	}
}
