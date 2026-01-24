package registry

type Solver = func([]byte) int

var r = make([]Solver, 49)

func Register(day, part int, s Solver) {
	r[inputToIndex(day, part)] = s
}

// Get returns nil for non-existent solutions.
func Get(day, part int) Solver {
	return r[inputToIndex(day, part)]
}

func inputToIndex(day, part int) int {
	return 2*(day-1) + (part - 1)
}
