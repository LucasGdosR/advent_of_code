package main

import (
	"aoc/2023/common"
	"bufio"
	"strings"
)

type xyz struct{ x, y, z int }

type eq struct {
	position xyz
	velocity xyz
}

const (
	start = 200000000000000
	end   = 400000000000000
)

func main() {
	eqs := readEqs()
	var result int
	for i, a := range eqs[:len(eqs)-1] {
		for _, b := range eqs[i+1:] {
			if intercept(a, b) {
				result++
			}
		}
	}
	println(result)
}

func intercept(a, b eq) bool {
	ax, ay := float64(a.position.x), float64(a.position.y)
	avx, avy := float64(a.velocity.x), float64(a.velocity.y)
	bx, by := float64(b.position.x), float64(b.position.y)
	bvx, bvy := float64(b.velocity.x), float64(b.velocity.y)

	/*
	   Parametric form: P = P0 + t*V
	   a: (ax + t*avx, ay + t*avy)
	   b: (bx + s*bvx, by + s*bvy)

	   ax + t*avx = bx + s*bvx
	   ay + t*avy = by + s*bvy

	   Solve for t:
	   t*avx - s*bvx = bx - ax
	   t*avy - s*bvy = by - ay
	*/

	den := avx*bvy - avy*bvx
	// Parallel lines (or same line)
	if den == 0 {
		return false
	}
	// Time for hailstone a to reach intersection.
	t := ((bx-ax)*bvy - (by-ay)*bvx) / den
	// Time for hailstone b to reach intersection.
	s := ((bx-ax)*avy - (by-ay)*avx) / den

	if t < 0 || s < 0 {
		return false
	}

	ix := ax + t*avx
	iy := ay + t*avy

	return ix >= start && ix <= end && iy >= start && iy <= end
}

func readEqs() []eq {
	input, closer := common.Open("input")
	defer closer()
	scanner := bufio.NewScanner(input)
	eqs := make([]eq, 0, 300)
	for scanner.Scan() {
		line := scanner.Text()
		pv := strings.Split(line, " @ ")
		p := strings.Split(pv[0], ", ")
		v := strings.Split(pv[1], ", ")
		eqs = append(eqs, eq{
			position: xyz{
				common.Atoi(p[0]),
				common.Atoi(p[1]),
				common.Atoi(p[2]),
			},
			velocity: xyz{
				common.Atoi(v[0]),
				common.Atoi(v[1]),
				common.Atoi(v[2]),
			},
		})
	}
	return eqs
}
