package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

Interval :: struct { l, r: i32 }

solve :: proc()
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)
    defer free_all(context.temp_allocator)

    p1, p2: int
    it := string(input)
    for l in strings.split_lines_iterator(&it)
    {
        i1, i2 := line_to_intervals(l)
        if contains(i1, i2) || contains(i2, i1) do p1 += 1
        if overlap(i1, i2) || overlap(i2, i1) do p2 += 1
    }
    fmt.println(p1, p2)
}

line_to_intervals :: proc(l: string) -> (i1, i2: Interval)
{
        i := strings.index_byte(l, '-')
        i1.l = i32(strconv.atoi(l[:i]))

        rest := l[i+1:]
        j := strings.index_byte(rest, ',')
        i1.r = i32(strconv.atoi(rest[:j]))

        rest = rest[j+1:]
        k := strings.index_byte(rest, '-')
        i2 = { l=i32(strconv.atoi(rest[:k])), r=i32(strconv.atoi(rest[k+1:])) }

        return
}

contains :: proc(i1, i2: Interval) -> bool
{
    return i1.l <= i2.l && i1.r >= i2.r
}

overlap :: proc(i1, i2: Interval) -> bool
{
    return (i1.r >= i2.l && i1.r <= i2.r) || (i1.l >= i2.l && i1.l <= i2.r)
}

/*
 * Visualization:
 * Draw the two intervals. Paint where they overlap.
 * Add a symbol when one of them is contained.
 */
W :: 1900
H :: 300
main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    defer delete(input)
    it := string(input)

    rl.InitWindow(W, H, "AoC 22.04")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    i1, i2: Interval
    { if l, ok := strings.split_lines_iterator(&it); ok do i1, i2 = line_to_intervals(l) }
    for !rl.WindowShouldClose()
    {
        if rl.IsKeyPressed(.SPACE)
        {
            line, ok := strings.split_lines_iterator(&it)
            if ok
            {
            i1, i2 = line_to_intervals(line)
            }
            else
            {
                // Draw done
            }
        }
        defer free_all(context.temp_allocator)
        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)
            draw_interval(i1, i2, 0)
            draw_interval(i2, i1, 1)
    }
}
    
draw_interval :: proc(i1, i2: Interval, dy: i32)
{
    // Overlap: RED; else: GREEN
    X :: 100
    Y :: 100
    DY :: 100
    MAX_INPUT :: 99
    SCALE :: (W - 2*X) / MAX_INPUT
    y := Y + DY*dy
    // Draw three line segments: GREEN, RED, GREEN
    if contains(i1, i2)
    {
        rl.DrawText("Contains!", W/2 - 40, y - 22, 20, rl.GOLD)
        rl.DrawLine(X + i1.l*SCALE, y, X + i2.l*SCALE, y, rl.GREEN)
        rl.DrawLine(X + i2.l*SCALE, y, X + i2.r*SCALE, y, rl.RED)
        rl.DrawLine(X + i2.r*SCALE, y, X + i1.r*SCALE, y, rl.GREEN)
    }
    else if contains(i2, i1) do rl.DrawLine(X + i1.l*SCALE, y, X + i1.r*SCALE, y, rl.RED)
    // Draw single RED segment
    // Draw single GREEN segment
    else if !overlap(i1, i2) && !overlap(i2, i1) do rl.DrawLine(X + i1.l*SCALE, y, X + i1.r*SCALE, y, rl.GREEN)
    // Draw two segments:
    else if i1.l < i2.l
    {
        rl.DrawLine(X + i1.l*SCALE, y, X + i2.l*SCALE, y, rl.GREEN)
        rl.DrawLine(X + i2.l*SCALE, y, X + i1.r*SCALE, y, rl.RED)
    }
    else
    {
        rl.DrawLine(X + i1.l*SCALE, y, X + i2.r*SCALE, y, rl.RED)
        rl.DrawLine(X + i2.r*SCALE, y, X + i1.r*SCALE, y, rl.GREEN)
    }
}