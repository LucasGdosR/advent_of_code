package main

import rl "vendor:raylib"
import "core:fmt"
import "core:math/linalg"
import "core:os"
import "core:strconv"
import "core:strings"

P1 :: 0
P2 :: 1
KNOTS :: 10
HEAD :: 0
P1_TAIL :: 1
P2_TAIL :: KNOTS - 1

knots: [KNOTS][2]i32
visited: [2]map[[2]i32]struct{}

solve :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    it := string(input)

    visited[P1][knots[P1_TAIL]] = struct{}{}
    visited[P2][knots[P2_TAIL]] = struct{}{}
    for line in strings.split_lines_iterator(&it) do process_line(line)
    fmt.println(len(visited[P1]), len(visited[P2]))
}

process_line :: proc(line: string)
{
    to_update: ^i32
    update: i32
    switch line[0]
    {
        case 'L': to_update, update = &knots[HEAD].x, -1
        case 'R': to_update, update = &knots[HEAD].x,  1
        case 'U': to_update, update = &knots[HEAD].y, -1
        case 'D': to_update, update = &knots[HEAD].y,  1
    }
    for _ in 0..<strconv.atoi(line[2:])
    {
        to_update^ += update
        for i in i32(1)..<KNOTS do if !pull_knot(i-1, i) do break
        visited[P1][knots[P1_TAIL]] = struct{}{}
        visited[P2][knots[P2_TAIL]] = struct{}{}
    }
}

pull_knot :: proc(head, tail: i32) -> (result: bool)
{
    if abs(knots[head].x - knots[tail].x) > 1 || abs(knots[head].y - knots[tail].y) > 1
    {
        knots[tail].x += clamp(knots[head].x - knots[tail].x, -1, 1)
        knots[tail].y += clamp(knots[head].y - knots[tail].y, -1, 1)
        result = true
    }
    return
}

W :: 1900
H :: 1000
PADDING :: 50
main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    it := string(input)

    visited[P1][knots[P1_TAIL]] = struct{}{}
    visited[P2][knots[P2_TAIL]] = struct{}{}

    rl.InitWindow(W, H, "AoC 22.09")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    frame_count: i32
    FRAME_CYCLE :: 10

    prev_knots: [KNOTS][2]i32
    for !rl.WindowShouldClose()
    {
        defer frame_count += 1

        // Simulation step
        if frame_count == FRAME_CYCLE
        {
            frame_count = 0
            prev_knots = knots
            line, ok := strings.split_lines_iterator(&it)
            if !ok do break // TODO: gracious finish
            process_line(line)
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.WHITE)

            // Blend `knots` and `prev_knots`
            t := f32(frame_count) / FRAME_CYCLE
            prev_blend := map_coord_to_screen(lerp(prev_knots[HEAD], knots[HEAD], t))
            rl.DrawCircleV(prev_blend, 5, rl.BLUE)
            for i in 1..<KNOTS
            {
                curr_blend := map_coord_to_screen(lerp(prev_knots[i], knots[i], t))
                color: rl.Color
                switch i
                {
                    case P1_TAIL:
                        color = rl.DARKGREEN
                    case P2_TAIL:
                        color = rl.DARKPURPLE
                    case:
                        color = rl.BLACK
                }
                rl.DrawCircleV(curr_blend, 4, rl.BLACK)
                rl.DrawLineEx(prev_blend, curr_blend, 3, rl.BROWN)
                prev_blend = curr_blend
            }

            // Draw `visited` P1 and P2 keys
            for pos in visited[P1] do rl.DrawCircleV(map_coord_to_screen(linalg.array_cast(pos, f32)), 2, rl.GREEN)
            for pos in visited[P2] do rl.DrawCircleV(map_coord_to_screen(linalg.array_cast(pos, f32)), 2, rl.PURPLE)
    }
}

map_coord_to_screen :: proc(coord: [2]f32) -> [2]f32
{
    MIN_X :: -52
    MAX_X :: 238
    MIN_Y :: -52
    MAX_Y :: 131
    X_SCALE :: (W - 2 * PADDING) / (MAX_X - MIN_X)
    Y_SCALE :: (H - 2 * PADDING) / (MAX_Y - MIN_Y)

    return { (coord.x - MIN_X) * X_SCALE + PADDING, (coord.y - MIN_Y) * Y_SCALE + PADDING }
}

lerp :: proc(start, end: [2]i32, t: f32) -> [2]f32
{
    return linalg.array_cast(start, f32) * (1 - t) + t * linalg.array_cast(end, f32)
}
