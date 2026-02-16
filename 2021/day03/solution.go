package day03

import (
	"bytes"

	"aoc/internal/registry"
)

func init() {
	registry.Register(3, 1, Part1)
	registry.Register(3, 2, Part2)
}

func Part1(input []byte) int {
	gamma, epsilon := part1(input)
	return gamma * epsilon
}

func part1(input []byte) (int, int) {
	var i, gamma int
	bitLen := bytes.IndexByte(input, '\n')
	lineLen := bitLen + 1
	counts := make([]int, bitLen)
	if bitLen == 12 {
		for i = 0; i < len(input); i += lineLen {
			counts[0] += int(input[i])
			counts[1] += int(input[i+1])
			counts[2] += int(input[i+2])
			counts[3] += int(input[i+3])
			counts[4] += int(input[i+4])
			counts[5] += int(input[i+5])
			counts[6] += int(input[i+6])
			counts[7] += int(input[i+7])
			counts[8] += int(input[i+8])
			counts[9] += int(input[i+9])
			counts[10] += int(input[i+10])
			counts[11] += int(input[i+11])
		}
	} else if bitLen == 5 {
		for i = 0; i < len(input); i += lineLen {
			counts[0] += int(input[i])
			counts[1] += int(input[i+1])
			counts[2] += int(input[i+2])
			counts[3] += int(input[i+3])
			counts[4] += int(input[i+4])
		}
	} else {
		// fallback
		for i = 0; i < len(input); i += lineLen {
			for j := range bitLen {
				counts[j] += int(input[i+j])
			}
		}
	}

	lineCount := i / lineLen
	majority := lineCount/2 + lineCount*'0'
	for _, c := range counts {
		gamma <<= 1
		if c > majority {
			gamma++
		}
	}
	return gamma, ((1 << bitLen) - 1) ^ gamma
}

func Part2(input []byte) int {
	oxygen, carbon := part2(input)
	return oxygen * carbon
}

func part2(input []byte) (int, int) {
	ones, zeroes := make([]int, 0, 512), make([]int, 0, 512)
	lineLen := bytes.IndexByte(input, '\n') + 1
	for i := 0; i < len(input); i += lineLen {
		if input[i] == '1' {
			ones = append(ones, i)
		} else {
			zeroes = append(zeroes, i)
		}
	}

	var O2, CO2 []int
	if len(ones) > len(zeroes) {
		O2, CO2 = ones, zeroes
	} else {
		O2, CO2 = zeroes, ones
	}

	for j := 1; len(O2) != 1; j++ {
		majority := countMajority(input, j, O2)
		var write int
		// This loop could be unrolled.
		for _, i := range O2 {
			if input[i+j] == majority {
				O2[write] = i
				write++
			}
		}
		O2 = O2[:write]
	}

	for j := 1; len(CO2) != 1; j++ {
		majority := countMajority(input, j, CO2)
		var write int
		// This loop could be unrolled.
		for _, i := range CO2 {
			if input[i+j] != majority {
				CO2[write] = i
				write++
			}
		}
		CO2 = CO2[:write]
	}

	return idxToInt(input, lineLen-1, O2[0]), idxToInt(input, lineLen-1, CO2[0])
}

func countMajority(input []byte, j int, idxs []int) byte {
	allZeroes := len(idxs) * '0'
	var count int
	for _, i := range idxs {
		count += int(input[i+j])
	}
	if count-allZeroes >= (len(idxs)+1)/2 {
		return '1'
	} else {
		return '0'
	}
}

func idxToInt(s []byte, bitLen, i int) int {
	var result int
	for j := range bitLen {
		result += int(s[i+j]-'0') << (bitLen - j - 1)
	}
	return result
}
