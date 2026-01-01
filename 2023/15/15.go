package main

import (
	"aoc/2023/common"
	"runtime"
	"slices"
	"syscall"
)

const BOXES = 256

type lens struct {
	label       []byte
	focalLength byte
}

func main() {
	thisProgram := common.Benchmarkee[int, int]{
		ST_Impl:  hashAndOrderST,
		MT_Impl:  hashAndOrderMT,
		Part1Str: "Hash sum",
		Part2Str: "Focusing power",
	}
	common.Benchmark(thisProgram, 1000)
}

func hashAndOrderST() common.Results[int, int] {
	mappedFile := common.Mmap("input")
	initializationSequence := mappedFile.File
	size := int(mappedFile.Size)
	defer syscall.Munmap(initializationSequence)

	var results common.Results[int, int]

	var HASH byte
	boxes := make([][]lens, BOXES)

	for l, r := 0, 0; r < size; r++ {
		b := initializationSequence[r]
		if b == '\n' {
			continue
		}
		if b == ',' {
			results.Part1 += int(HASH)
			HASH = 0
			l = r + 1
		} else {
			switch b {
			case '-':
				box := boxes[HASH]
				for i, lens := range box {
					if slices.Equal(lens.label, initializationSequence[l:r]) {
						boxes[HASH] = append(box[:i], box[i+1:]...)
						break
					}
				}
			case '=':
				box := boxes[HASH]
				label := initializationSequence[l:r]
				focalLength := initializationSequence[r+1] - '0'
				found := false
				for i, lens := range box {
					if slices.Equal(lens.label, label) {
						box[i].focalLength = focalLength
						found = true
						break
					}
				}
				if !found {
					boxes[HASH] = append(box, lens{label: label, focalLength: focalLength})
				}
			}
			HASH += b
			HASH *= 17
		}

	}
	results.Part1 += int(HASH)

	for i, box := range boxes {
		for j, lens := range box {
			results.Part2 += (i + 1) * (j + 1) * int(lens.focalLength)
		}
	}
	return results
}

// Single producer parses the input, calculates hash, and sends job to consumers based on hash.
// When the input is over, producer closes channels. Consumers send partial sum on channels.
// Producer reduces partial sums.
type job struct {
	index, op byte
	label     []byte
}

func hashAndOrderMT() common.Results[int, int] {
	mappedFile := common.Mmap("input")
	initializationSequence := mappedFile.File
	size := int(mappedFile.Size)
	defer syscall.Munmap(initializationSequence)
	var results common.Results[int, int]
	var HASH byte

	// Consumers.
	numWorkers := runtime.GOMAXPROCS(0)
	boxesPerWorker := BOXES / numWorkers
	partialResults := make(chan int, numWorkers)
	jobs := make([]chan job, numWorkers)
	for i := range int(numWorkers) {
		jobs[i] = make(chan job, 1)
		go func(i int) {
			// Subtract start from job's hash to get box index.
			start := i * boxesPerWorker
			// Create local slice of lens.
			numBoxes := boxesPerWorker
			if i == numWorkers-1 {
				numBoxes = BOXES - start
			}
			s := byte(start)
			boxes := make([][]lens, numBoxes)

			// Consume all jobs.
			for j := range jobs[i] {
				bi := j.index - s
				box := boxes[bi]
				switch j.op {
				case '-':
					for i, lens := range box {
						if slices.Equal(lens.label, j.label) {
							boxes[bi] = append(box[:i], box[i+1:]...)
							break
						}
					}
				case '=':
					lb := j.label[:len(j.label)-2]
					focalLength := j.label[len(j.label)-1] - '0'
					found := false
					for i, lens := range box {
						if slices.Equal(lens.label, lb) {
							box[i].focalLength = focalLength
							found = true
							break
						}
					}
					if !found {
						boxes[bi] = append(box, lens{label: lb, focalLength: focalLength})
					}
				}
			}
			// Reduce results and return to producer.
			var result int
			for i, box := range boxes {
				for j, lens := range box {
					result += (i + start + 1) * (j + 1) * int(lens.focalLength)
				}
			}
			partialResults <- result
		}(i)
	}

	// Producer.
	for l, r := 0, 0; r < size; r++ {
		b := initializationSequence[r]
		if b == '\n' {
			continue
		}
		if b == ',' {
			results.Part1 += int(HASH)
			HASH = 0
			l = r + 1
			continue
		}
		var isJob bool
		var j job
		switch b {
		case '-':
			isJob = true
			j = job{index: HASH, op: '-', label: initializationSequence[l:r]}
		case '=':
			isJob = true
			j = job{index: HASH, op: '=', label: initializationSequence[l : r+2]}
		}
		if isJob {
			ji := HASH / byte(boxesPerWorker)
			jobs[ji] <- j
		}
		HASH += b
		HASH *= 17
	}

	// Reduce partial results.
	for i := range numWorkers {
		close(jobs[i])
	}
	results.Part1 += int(HASH)

	for range numWorkers {
		results.Part2 += <-partialResults
	}
	close(partialResults)

	return results
}
