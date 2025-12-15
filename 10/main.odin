package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

//______________________________
// Regular solution
//______________________________

solve :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)

    p1: int
    X, cycle := 1, 1
    it := string(input)
    for line in strings.split_lines_iterator(&it)
    {
        process_cycle(X, &cycle, &p1)
        if line[0] == 'a'
        {
            process_cycle(X, &cycle, &p1)
            X += strconv.atoi(line[5:])
        }
    }
    fmt.println(p1)
}

process_cycle :: proc(X: int, #no_alias cycle, p1: ^int)
{
    cycle_mod := cycle^ % 40
    if cycle_mod == 20 do p1^ += X * cycle^
    pixel_h := (cycle^ - 1) % 40
    fmt.print(pixel_h >= X - 1 && pixel_h <= X + 1 ? '#' : '.')
    if cycle_mod == 0 do fmt.println()
    cycle^ += 1
}

//______________________________
// Verbose solution
//______________________________

main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)

    solve_and_display_p1(input)
    fmt.println()
    solve_p2(input)
}

solve_and_display_p1 :: proc(input: []byte)
{
    p1: int
    X, cycle := 1, 1
    it := string(input)
    fmt.println("Cycle\t\tX\t\tSignal strength\t\tInstruction")
    for line in strings.split_lines_iterator(&it)
    {
        print_p1_line(cycle, X, line)
        add_interesting_signal_strength(X, &cycle, &p1)
        if line[0] == 'a'
        {
            print_p1_line(cycle, X, line)
            add_interesting_signal_strength(X, &cycle, &p1)
            X += strconv.atoi(line[5:])
        }
    }
    fmt.println("P1 solution:", p1)
}

print_p1_line :: proc(cycle, X: int, instruction: string) { fmt.printfln("%d\t\t%d\t\t%d\t\t\t%s", cycle, X, cycle * X, instruction) }

add_interesting_signal_strength :: proc(X: int, cycle, p1: ^int)
{
    if cycle^ % 40 == 20
    {
        p1^ += X * cycle^
        fmt.println("\t\t\t\t^ This was interesting:", p1^)
    }
    cycle^ += 1
}

solve_p2 :: proc(input: []byte)
{
    X, cycle := 1, 1
    it := string(input)
    for line in strings.split_lines_iterator(&it)
    {
        cycle = print_pixel(X, cycle)
        if line[0] == 'a'
        {
            cycle = print_pixel(X, cycle)
            X += strconv.atoi(line[5:])
        }
    }
}

print_pixel :: proc(X, cycle: int) -> int
{
    pixel_h := (cycle - 1) % 40
    fmt.print(pixel_h >= X - 1 && pixel_h <= X + 1 ? '#' : '.')
    if cycle % 40 == 0 do fmt.println()
    return cycle + 1
}