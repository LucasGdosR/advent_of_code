package day04

import (
	"aoc/internal/registry"
)

func init() {
	registry.Register(4, 1, Part1)
	registry.Register(4, 2, Part2)
}

const (
	rows                         = 5
	cols                         = 5
	boardSize                    = rows * cols
	maxRandom                    = 100
	maxBoards                    = 100
	exampleBoardPatternLineBreak = 27*3 - 10 - 1
	exampleBoardPatternStart     = exampleBoardPatternLineBreak + 1
	realBoardPatternStart        = maxRandom*3 - 10
	boardPatternLen              = boardSize*3 + 1
	numberToBoardShift           = 5 // MSB(boardPatternLen) + 1
	cache                        = 1
	cacheIdx                     = boardSize + rows + cols
	boardsSize                   = boardSize + rows + cols + cache
)

func Part1(input []byte) int {
	numberToBoard := make([][]int, maxRandom)
	boardBackingSlice := make([]int, len(numberToBoard)*35)
	for i, j := 0, 0; i < len(numberToBoard); i, j = i+1, j+35 {
		numberToBoard[i] = boardBackingSlice[j : j : j+35]
	}
	boards := make([][boardsSize]byte, maxBoards)

	unmarked, last := part1(input, numberToBoard, &boards)
	return unmarked * last
}

func part1(input []byte, numberToBoard [][]int, boardsPtr *[][boardsSize]byte) (int, int) {
	for i := range numberToBoard {
		numberToBoard[i] = numberToBoard[i][:0]
	}
	clear(*boardsPtr)

	parseBoards(input, numberToBoard, boardsPtr)
	var marked [2]uint64
	boards := *boardsPtr
	for i, n := 0, byte(0); ; i++ {
		if input[i] == ',' {
			marked[(n&64)>>6] |= 1 << (n & 63)
			for _, b := range numberToBoard[n] {
				bi, bii := b>>numberToBoardShift, b&((1<<numberToBoardShift)-1)
				if markAndCheckBingo(boards[bi][:], bii) {
					return sumUnmarked(boards[bi][:boardSize], marked), int(n)
				}
			}
			n = 0
		} else {
			n = n*10 + input[i] - '0'
		}
	}
}

func Part2(input []byte) int {
	numberToBoard := make([][]int, maxRandom)
	boardBackingSlice := make([]int, len(numberToBoard)*35)
	for i, j := 0, 0; i < len(numberToBoard); i, j = i+1, j+35 {
		numberToBoard[i] = boardBackingSlice[j : j : j+35]
	}
	boards := make([][boardsSize]byte, maxBoards)

	unmarked, last := part2(input, numberToBoard, &boards)
	return unmarked * last
}

func part2(input []byte, numberToBoard [][]int, boardsPtr *[][boardsSize]byte) (int, int) {
	for i := range numberToBoard {
		numberToBoard[i] = numberToBoard[i][:0]
	}
	clear(*boardsPtr)

	parseBoards(input, numberToBoard, boardsPtr)
	boards := *boardsPtr
	var marked [2]uint64
	var boardsToGo int
	if input[exampleBoardPatternLineBreak] == '\n' {
		boardsToGo = 3
	} else {
		boardsToGo = 100
	}
	for i, n := 0, byte(0); ; i++ {
		if input[i] == ',' {
			marked[(n&64)>>6] |= 1 << (n & 63)
			for _, x := range numberToBoard[n] {
				bi, bii := x>>numberToBoardShift, x&((1<<numberToBoardShift)-1)
				if boards[bi][cacheIdx] == 0 {
					if markAndCheckBingo(boards[bi][:], bii) {
						if boardsToGo == 1 {
							return sumUnmarked(boards[bi][:boardSize], marked), int(n)
						} else {
							boards[bi][cacheIdx] = 1
							boardsToGo--
						}
					}
				}
			}
			n = 0
		} else {
			n = n*10 + input[i] - '0'
		}
	}
}

func parseBoards(input []byte, numberToBoard [][]int, boardsPtr *[][boardsSize]byte) {
	boards := *boardsPtr
	// Exploit structured input.
	var boardPatternStart int
	if input[exampleBoardPatternLineBreak] == '\n' {
		boardPatternStart = exampleBoardPatternStart
	} else {
		boardPatternStart = realBoardPatternStart
	}

	/*  ii: inputIndex
	 *  bi: boardIndex -> 0-99
	 *   j: inputOffset
	 * bii: boardInnerIndex -> 0-24
	 *   n: parsedInput
	 */
	for ii, bi := boardPatternStart, 0; ii < len(input); ii, bi = ii+boardPatternLen, bi+1 {
		for j, bii := 1, 0; j < boardPatternLen-2; j, bii = j+3, bii+1 {
			n := input[ii+j+1] - '0'
			if input[ii+j] > ' ' {
				n += 10 * (input[ii+j] - '0')
			}
			numberToBoard[n] = append(numberToBoard[n], (bi<<numberToBoardShift)|bii)
			boards[bi][bii] = n
		}
	}
}

func markAndCheckBingo(b []byte, i int) bool {
	row, col := i/cols, i%cols
	b[boardSize+row]++
	b[boardSize+rows+col]++
	return b[boardSize+row] == 5 || b[boardSize+rows+col] == 5
}

func sumUnmarked(b []byte, marked [2]uint64) int {
	var result int
	for _, n := range b {
		if marked[(n&64)>>6]&(1<<(n&63)) == 0 {
			result += int(n)
		}
	}
	return result
}
