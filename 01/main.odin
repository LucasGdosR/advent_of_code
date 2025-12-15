package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

// Simple solution to the puzzle.
solve :: proc()
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)
    defer free_all(context.temp_allocator)
    
    max_array: [3]int
    max_slice := max_array[:]
    curr_calories: int
    it := string(input)
    for line in strings.split_lines_iterator(&it)
    {
        if len(line) == 0
        {
            put_elf_in_array(max_slice, curr_calories)
            curr_calories = 0
        }
        else
        {
            curr_calories += strconv.atoi(line)
        }
    }
    put_elf_in_array(max_slice, curr_calories)
    fmt.println(max_slice[0], max_slice[0] + max_slice[1] + max_slice[2])
}

// Helper function
put_elf_in_array :: proc(max_slice: []int, candidate: int)
{
    candidate := candidate
    for &elf in max_slice
    {
        if elf < candidate
        {
            elf, candidate = candidate, elf
        }
    }
}

/**
 * Visualization idea:
 * Have one bar representing the current sum.
 * When the current sum ends, compare it with the max bar.
 * If it's larger, swap it. Do the same procedure for the second and third bars.
 *
 * Speeding up the visualization:
 * Treat it as a multi-threaded program and have 4 instances of this visualization
 * running at 4 different chunks of the input. Merge all resulting slices into the
 * whole solution.
 */
W :: 1900
H :: 1000
ROWS :: 3
COLS :: 4
THREADS :: ROWS * COLS
TOP_THREE :: 3
State :: enum {
    SUM,
    COMPARE,
    LAST_COMPARE,
    SOLVED
}
main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    
    split_input := share_work(input)
    it: [THREADS]string
    for s, i in split_input
    {
        it[i] = string(s)
    }

    max_array: [TOP_THREE * THREADS]i32
    max_slice := max_array[:]
    curr_calories: [THREADS]i32
    state : [THREADS]State
    max_i : [THREADS]int
    fully_solved: bool
    
    rl.InitWindow(W, H, "AoC 22/01")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose()
    {
        for i in 0..<THREADS
        {
        switch state[i] {
            case .SUM:
                line, ok := strings.split_lines_iterator(&it[i])
                if !ok
                {
                    state[i] = .LAST_COMPARE
                }
                else if len(line) != 0
                {
                    curr_calories[i] += i32(strconv.atoi(line))
                }
                else
                {
                    state[i] = .COMPARE
                }
            case .COMPARE:
                curr_max := max_slice[TOP_THREE * i + max_i[i]]
                if curr_calories[i] > curr_max
                {
                    curr_calories[i], max_slice[TOP_THREE * i + max_i[i]] = curr_max, curr_calories[i]
                }
                if max_i[i] < TOP_THREE - 1
                {
                    max_i[i] += 1
                }
                else
                {
                    max_i[i] = 0
                    curr_calories[i] = 0
                    state[i] = .SUM
                }
            case .LAST_COMPARE:
                if i == THREADS - 1 && max_i[THREADS - 1] < TOP_THREE
                {
                    this_i :: THREADS - 1
                    curr_max := max_slice[TOP_THREE * this_i + max_i[this_i]]
                    if curr_calories[this_i] > curr_max
                    {
                        curr_calories[this_i], max_slice[TOP_THREE * this_i + max_i[this_i]] = curr_max, curr_calories[this_i]
                    }
                    max_i[this_i] += 1
                    if max_i[this_i] == TOP_THREE
                    {
                        curr_calories[this_i] = 0
                    }
                }
                else
                {
                    state[i] = .SOLVED
                    all_solved := true
                    for s in state do all_solved &= s == .SOLVED
                    if all_solved
                    {
                        delete(input)
                        slice.reverse_sort(max_slice)
                        fully_solved = true
                    }
                }
            case .SOLVED:
            }
        }
        
        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)
            
            cell_w :: W/COLS
            cell_h :: H/ROWS
            spacing :: cell_w/10
            hpad :: cell_w/3 - 2*spacing
            vpad :: cell_h/5
            bar_w :: (cell_w - 2*hpad - 4*spacing) / 4
            bar_h :: cell_h - 2*vpad
            
            // Draw grid
            for i in i32(1)..<ROWS do rl.DrawLine(0, cell_h*i, W, cell_h*i, rl.RAYWHITE)
            for i in i32(1)..<COLS do rl.DrawLine(cell_w*i, 0, cell_w*i, H, rl.RAYWHITE)

            for i in i32(0)..<THREADS
            {
                row := i / COLS
                col := i % COLS

                top := row * cell_h
                bot := top + cell_h
                left := col * cell_w
                text_h := bot - vpad + 5
              
                normal_h := max(curr_calories[i], max_slice[TOP_THREE * i])
                // Current sum
                this_h := bar_h * curr_calories[i] / normal_h
                this_x := left + hpad
                rl.DrawRectangle(this_x, bot - vpad - this_h, bar_w, this_h, rl.ORANGE)
                rl.DrawText("Current", this_x, text_h, 20, rl.RAYWHITE)
                rl.DrawText(rl.TextFormat("%d", curr_calories[i]), this_x, top + vpad - 20, 16, rl.RAYWHITE)
                // Max
                this_h = bar_h * max_slice[TOP_THREE * i] / normal_h
                this_x = left + hpad + 2*spacing + bar_w
                rl.DrawRectangle(this_x, bot - vpad - this_h, bar_w, this_h, rl.RED)
                rl.DrawText("1st", this_x, text_h, 20, rl.RAYWHITE)
                rl.DrawText(rl.TextFormat("%d", max_slice[TOP_THREE * i]), this_x, top + vpad - 20, 16, rl.RAYWHITE)
                // Second
                this_h = bar_h * max_slice[TOP_THREE * i + 1] / normal_h
                this_x = left + hpad + 3*spacing + 2*bar_w
                rl.DrawRectangle(this_x, bot - vpad - this_h, bar_w, this_h, rl.BLUE)
                rl.DrawText("2nd", this_x, text_h, 20, rl.RAYWHITE)
                rl.DrawText(rl.TextFormat("%d", max_slice[TOP_THREE * i + 1]), this_x, top + vpad - 20, 16, rl.RAYWHITE)
                // Third
                this_h = bar_h * max_slice[TOP_THREE * i + 2] / normal_h
                this_x = left + hpad + 4*spacing + 3*bar_w
                rl.DrawRectangle(this_x, bot - vpad - this_h, bar_w, this_h, rl.GREEN)
                rl.DrawText("3rd", this_x, text_h, 20, rl.RAYWHITE)
                rl.DrawText(rl.TextFormat("%d", max_slice[TOP_THREE * i + 2]), this_x, top + vpad - 20, 16, rl.RAYWHITE)
            }

            if fully_solved
            {
                rec : rl.Rectangle = { W/2 - 250, H/2 - 50, 500, 100 }
                rl.DrawRectangleRec(rec, rl.BLACK)
                rl.DrawRectangleLinesEx(rec, 2, rl.LIME)
                rl.DrawText(rl.TextFormat("Part 1 solution: %d\nPart 2 solution: %d",max_slice[0], max_slice[0]+max_slice[1]+max_slice[2]),
                    W/2 - 240, H/2 - 40, 40, rl.LIME)
            }
    }
}

// Split input roughly in THREADS chunks. Each chunk ends in \n\n, except last.
share_work :: proc (input: []byte) -> [THREADS][]byte
{
    length := len(input)
    inc := length / THREADS
    // Fixed arrays are copied. They're not pointers, so it's safe to return them.
    result: [THREADS][]byte
    start, end: int
    for i in 0..<THREADS-1
    {
        end = start + inc
        line_break: bool
        for
        {
            if input[end] == '\n'
            {
                if line_break
                {
                    result[i] = input[start:end+1]
                    break
                }
                line_break = true
            }
            else
            {
                line_break = false
            }
            end += 1
        }
        start = end + 1
    }
    result[THREADS-1] = input[start:]

    return result
}