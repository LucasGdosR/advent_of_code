package main

import rl "vendor:raylib"
import q "core:container/queue"
import "core:fmt"
import "core:os"

WIDTH :: 136
HEIGHT :: 41
LINE_BREAK :: 1

Directions :: [4][2]i32{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

E :: struct {
    coord: [2]i32,
    steps: int,
}

solve :: proc()
{
    grid, start, p2_starts, end := get_grid_starts_and_end()
    p1 := bfs(grid, start[:], end)
    fmt.println(p1, min(p1, bfs(grid, p2_starts[:], end)))
}

get_grid_starts_and_end :: proc() -> (grid: ^[HEIGHT][WIDTH+LINE_BREAK]u8, start: [1][2]i32, p2_starts: [dynamic][2]i32, end: [2]i32)
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    grid = cast(^[HEIGHT][WIDTH+LINE_BREAK]u8)raw_data(input)
    p2_starts = make([dynamic][2]i32)
    start, end = find_starts_and_end(grid, &p2_starts)
    grid[start[0].x][start[0].y], grid[end.x][end.y] = 'a', 'z'
    return
}

find_starts_and_end :: proc(grid: ^[HEIGHT][WIDTH+LINE_BREAK]u8, p2_starts: ^[dynamic][2]i32) -> (start: [1][2]i32, end: [2]i32)
{
    for i in i32(0)..<HEIGHT do for j in i32(0)..<WIDTH do switch grid[i][j]
    {
        case 'S': start = {{ i, j }}
        case 'E': end = { i, j }
        case 'a': append(p2_starts, [2]i32{ i, j })
        case:
    }
    return
}

bfs :: proc(grid: ^[HEIGHT][WIDTH+LINE_BREAK]u8, start: [][2]i32, end: [2]i32) -> int
{
    visited := make(map[[2]i32]struct{})
    defer delete(visited)

    queue: q.Queue(E)
    q.init(&queue)
    defer q.destroy(&queue)

    for s in start
    {
        visited[s] = struct{}{}
        q.append(&queue, E{ coord=s, steps=0})
    }

    curr: E
    for queue.len != 0
    {
        curr = q.pop_front(&queue)
        curr_char := grid[curr.coord.x][curr.coord.y]
        for D in Directions
        {
            neighbor := curr.coord + D
            if is_in_bounds(neighbor) && grid[neighbor.x][neighbor.y] <= curr_char + 1 && neighbor not_in visited
            {
                if neighbor == end do return curr.steps + 1
                else
                {
                    visited[neighbor] = struct{}{}
                    q.append(&queue, E{coord=neighbor, steps=curr.steps+1})
                }
            }
        }
    }
    return max(int)
}

is_in_bounds :: proc(p: [2]i32) -> bool
{
    return p.x >= 0 && p.x < HEIGHT && p.y >= 0 && p.y < WIDTH
}

// Visualization:
// Make a heightmap. Color visited tiles. Advance all neighbors from all starting points once every frame.
W :: 1900
H :: 650

point_state :: struct
{
    height: u8,
    who_visited: u32,
    coord: [2]i32
}

SENTINEL :: 1
SENTINEL_VALUE :: 'z' + 2
state :: struct
{
    colored_grid: [HEIGHT + 2*SENTINEL][WIDTH + 2*SENTINEL]point_state,
    queue: q.Queue(point_state),
    colors: []rl.Color,
    end: [2]i32,
    steps: i32,
    found: bool
}

main :: proc()
{
    s: state
    init_state(&s)

    rl.InitWindow(W, H, "AoC 2022.12")
    defer rl.CloseWindow()
    rl.SetTargetFPS(10)

    font := rl.GetFontDefault()

    for !rl.WindowShouldClose()
    {
        defer free_all(context.temp_allocator)
        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)
            for i in SENTINEL..<HEIGHT+SENTINEL do for j in SENTINEL..<WIDTH+SENTINEL
            {
                rl.DrawTextCodepoint(font, rune(s.colored_grid[i][j].height), {f32(j*13), f32(i*13 + 50)}, 13, s.colors[s.colored_grid[i][j].who_visited])
            }
            if s.found do rl.DrawText(fmt.ctprint("Found after", s.steps, "steps."), 10, 30, 20, rl.WHITE)

        // Advance simulation by 1 step
        if !s.found do s.steps += 1
        // Drain current queue
        curr_len := q.len(s.queue)
        for i in 0..<curr_len
        {
            curr := q.pop_front(&s.queue)
            for d in Directions
            {
                // This is simplified due to having sentinels on the borders.
                neighbor := &s.colored_grid[curr.coord.x + d.x][curr.coord.y + d.y]
                if neighbor.height <= curr.height + 1 && neighbor.who_visited == 0
                {
                    neighbor.who_visited = curr.who_visited
                    q.append(&s.queue, neighbor^)
                    if neighbor.coord == s.end do s.found = true
                }
            }
        }
    }
}

init_state :: proc(s: ^state)
{
    // Sentinels in grid
    for i in 1..=HEIGHT
    {
        s.colored_grid[i][0].height = SENTINEL_VALUE
        s.colored_grid[i][WIDTH+SENTINEL].height = SENTINEL_VALUE
    }
    for j in 1..=WIDTH
    {
        s.colored_grid[0][j].height = SENTINEL_VALUE
        s.colored_grid[HEIGHT+SENTINEL][j].height = SENTINEL_VALUE
    }

    // Init queue
    q.init(&s.queue)

    input, ok := os.read_entire_file("input")
    who_visited: u32
    for i in i32(0)..<HEIGHT do for j in i32(0)..<WIDTH
    {
        state: point_state = {
            coord={i+SENTINEL, j+SENTINEL},
            height=u8(input[i * (WIDTH + LINE_BREAK) + j]),
        }
        switch state.height
        {
            // Init `end`
            case 'E':
                s.end = {i+SENTINEL, j+SENTINEL}
                state.height = 'z'
            // Init `start`
            case 'S':
                state.height = 'a'
        }
        if state.height == 'a'
        {
            // Fill queue
            who_visited += 1
            state.who_visited = who_visited
            q.append(&s.queue, state)

        }
        s.colored_grid[i+SENTINEL][j+SENTINEL] = state
    }

    // Init colors
    colors := make([dynamic]rl.Color, who_visited + 1)
    for i in 1..=u32(who_visited)
    {
        hue := f32(i * 360) / f32(who_visited)
        color := rl.ColorFromHSV(hue, 0.8, 0.9)
        colors[i] = color
    }
    s.colors = colors[:]
}