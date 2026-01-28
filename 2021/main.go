package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	_ "aoc/day01"
	_ "aoc/day02"
	_ "aoc/day03"
	_ "aoc/day04"
	"aoc/internal/registry"
)

type httpError struct {
	status int
	err    error
}

func (e *httpError) Error() string {
	return e.err.Error()
}

func (e *httpError) Unwrap() error {
	return e.err
}

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /solve/{day}/{part}", func(w http.ResponseWriter, r *http.Request) {
		solver, day, err := getSolver(r)
		if err != nil {
			var he *httpError
			if errors.As(err, &he) {
				http.Error(w, he.Error(), he.status)
				return
			}
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		input, err := os.ReadFile(fmt.Sprintf("day%02d/testdata/input", day))
		if err != nil {
			http.Error(w, "input file not found", http.StatusInternalServerError)
			return
		}

		result := solver(input)
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]int{"answer": result})
	})

	mux.HandleFunc("POST /solve/{day}/{part}", func(w http.ResponseWriter, r *http.Request) {
		solver, _, err := getSolver(r)
		if err != nil {
			var he *httpError
			if errors.As(err, &he) {
				http.Error(w, he.Error(), he.status)
				return
			}
			http.Error(w, "internal error", http.StatusInternalServerError)
			return
		}

		input, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 200*1024))
		if err != nil {
			http.Error(w, "input too large", http.StatusRequestEntityTooLarge)
			return
		}

		defer func() {
			if r := recover(); r != nil {
				http.Error(w, "error solving input", http.StatusInternalServerError)
			}
		}()

		result := solver(input)
		w.Header().Set("Content-Type", "application/json")
		// Impossible error. `result` is type checked to be int.
		_ = json.NewEncoder(w).Encode(map[string]int{"answer": result})
	})

	server := &http.Server{
		Addr:         ":8080",
		Handler:      mux,
		ReadTimeout:  5 * time.Second,
		WriteTimeout: 5 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	log.Println("listening on :8080")
	log.Fatal(server.ListenAndServe())
}

func getSolver(r *http.Request) (registry.Solver, int, error) {
	var errs []error
	day, err := strconv.Atoi(r.PathValue("day"))
	if err != nil {
		errs = append(errs, fmt.Errorf("day is not an integer"))
	} else if day > 25 || day <= 0 {
		errs = append(errs, fmt.Errorf("day out of bounds: %d", day))
	}

	part, err := strconv.Atoi(r.PathValue("part"))
	if err != nil {
		errs = append(errs, fmt.Errorf("part is not an integer"))
	} else if part > 2 || part <= 0 {
		errs = append(errs, fmt.Errorf("part out of bounds: %d", part))
	} else if day == 25 && part == 2 {
		errs = append(errs, fmt.Errorf("day 25 has no part 2"))
	}

	if len(errs) > 0 {
		return nil, day, &httpError{
			status: http.StatusBadRequest,
			err:    errors.Join(errs...),
		}
	}

	solver := registry.Get(day, part)
	if solver == nil {
		return nil, day, &httpError{
			status: http.StatusNotImplemented,
			err:    fmt.Errorf("solver not implemented for day %d part %d", day, part),
		}
	}

	return solver, day, nil
}
