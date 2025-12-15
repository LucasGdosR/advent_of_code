package main

import "core:fmt"
import "core:strconv"
import "core:strings"
import "core:os"
import vmem "core:mem/virtual"
import rl "vendor:raylib"

Cell :: enum { Air, Sand, Rock }

ENTRY :: 500
NUMBER_OF_LINES :: 141

solve :: proc()
{
    arena: vmem.Arena
    allocator := vmem.arena_allocator(&arena)
    defer vmem.arena_destroy(&arena)
    context.allocator = allocator

    grid, entry := build_grid()

    count: int
    stack := make([dynamic][2]i32, 0, len(grid))
    append(&stack, [2]i32{entry, 0})

    for p, void := stack[len(stack) - 1], i32(len(grid) - 2); p.y != void; p = stack[len(stack) - 1] do drop_sand(&grid, p, &stack, &count)
    fmt.println("Part 1:", count)

    first_row := grid[0]
    for first_row[entry] != .Sand do drop_sand(&grid, stack[len(stack) - 1], &stack, &count)
    fmt.println("Part 2:", count)
}

drop_sand :: proc(grid: ^[][]Cell, p: [2]i32, stack: ^[dynamic][2]i32, count: ^int)
{
    if grid[p.y+1][p.x] == .Air do append(stack, [2]i32{p.x, p.y+1})
    else if grid[p.y+1][p.x-1] == .Air do append(stack, [2]i32{p.x-1, p.y+1})
    else if grid[p.y+1][p.x+1] == .Air do append(stack, [2]i32{p.x+1, p.y+1})
    else
    {
        pop(stack)
        grid[p.y][p.x] = .Sand
        count^ += 1
    }
}

build_grid :: proc() -> ([][]Cell, i32)
{
    // Read file
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)
    defer free_all(context.temp_allocator)

    // Store parsed info to get grid dimensions
    paths: [NUMBER_OF_LINES][dynamic][2]i32
    max_x, max_y: i32
    min_x : i32 = ENTRY

    // Parse file
    it := string(input)
    idx: i32
    for path in strings.split_lines_iterator(&it)
    {
        points := &paths[idx]
        points^ = make([dynamic][2]i32, context.temp_allocator)
        idx += 1
        path := path

        for point in strings.split_iterator(&path, " -> ")
        {
            x_int, _ := strconv.parse_int(point[:3], base=10)
            y_int, _ := strconv.parse_int(point[4:], base=10)
            x := i32(x_int)
            y := i32(y_int)
            append(points, [2]i32{x, y})
            if x < min_x do min_x = x
            if x > max_x do max_x = x
            if y > max_y do max_y = y
        }
    }

    // Get grid dimensions
    PART_2 :: 2
    height := max_y - 0 + 1 + PART_2
    if ENTRY - height < min_x do min_x = ENTRY - height
    if ENTRY + height > max_x do max_x = ENTRY + height
    width := max_x - min_x + 1

    // Create and fill grid
    grid := make([][]Cell, height)
    for y in 0..<height
    {
        grid[y] = make([]Cell, width)
    }
    for x in 0..<width do grid[height-1][x] = .Rock

    for path in paths do for i in 1..<len(path)
    {
        src, dst := path[i-1], path[i]
        // Vertical
        if src.x == dst.x
        {
            x := src.x - min_x
            start := min(src.y, dst.y)
            end := max(src.y, dst.y)
            for y in start..=end do grid[y][x] = .Rock
        }
        else // Horizontal
        {
            y := src.y
            start := min(src.x, dst.x) - min_x
            end := max(src.x, dst.x) - min_x
            for x in start..=end do grid[y][x] = .Rock
        }
    }

    return grid, ENTRY - min_x
}

W :: 1900
H :: 1000
X_PADDING :: 50
Y_PADDING :: 50
w :: W - 2 * X_PADDING
h :: H - 2 * Y_PADDING
main :: proc()
{
    permanent_arena: vmem.Arena
    allocator := vmem.arena_allocator(&permanent_arena)
    defer vmem.arena_destroy(&permanent_arena)
    context.allocator = allocator

    grid, entry := build_grid()

    count: int
    stack := make([dynamic][2]i32, 0, len(grid))
    append(&stack, [2]i32{entry, 0})

    part_1, part_2: int

    rl.InitWindow(W, H, "AoC 2022.14")
    defer rl.CloseWindow()
    rl.BeginDrawing()
        rl.ClearBackground(rl.WHITE)
        draw_grid(grid, entry)
    rl.EndDrawing()
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose()
    {
        // Simulate until it's over
        if part_2 == 0
        {
            p := stack[len(stack) - 1]
            drop_sand(&grid, p, &stack, &count)

            // End part 1:
            if part_1 == 0 && stack[len(stack) - 1].y == i32(len(grid) - 2) do part_1 = count

            // End part 2:
            if grid[0][entry] == .Sand do part_2 = count

            rl.BeginDrawing()
            defer rl.EndDrawing()
                if part_1 != 0 do draw_p1_result(part_1)
                if part_2 != 0 do draw_p2_result(part_2)
                else do draw_dropping_sand(grid, p)
        }
        else
        {
            // For closing the window after the visualization is done.
            rl.BeginDrawing()
            rl.EndDrawing()
        }
    }
}

draw_grid :: proc(g: [][]Cell, entry: i32)
{
    height := i32(len(g))
    width := i32(len(g[0]))

    cell_w := w / width
    cell_h := h / height

    for y in 0..<height do for x in 0..<width
    {
        screen_x := X_PADDING + x * cell_w
        screen_y := Y_PADDING + y * cell_h
        if g[y][x] == .Rock do rl.DrawRectangle(screen_x, screen_y, cell_w, cell_h, rl.DARKGRAY)
        rl.DrawRectangleLines(screen_x, screen_y, cell_w, cell_h, rl.LIGHTGRAY)
    }
    entry_x := X_PADDING + entry * cell_w
    rl.DrawCircle(entry_x + cell_w/2, Y_PADDING, 5, rl.RED)
}

draw_dropping_sand :: proc(g: [][]Cell, p: [2]i32)
{
    height := i32(len(g))
    width := i32(len(g[0]))

    cell_w := w / width
    cell_h := h / height

    screen_x := X_PADDING + p.x * cell_w
    screen_y := Y_PADDING + p.y * cell_h

    color := g[p.y][p.x] == .Sand ? rl.BEIGE : rl.ORANGE
    rl.DrawCircle(screen_x + cell_w/2, screen_y + cell_h/2, f32(cell_w) / 2 * 0.8, color)
}

draw_p1_result :: proc(result: int)
{
    text := fmt.ctprintf("Part 1: %d", result)
    rl.DrawText(text, 10, 10, 20, rl.BLACK)
}

draw_p2_result :: proc(result: int)
{
    text := fmt.ctprintf("Part 2: %d", result)
    rl.DrawText(text, 10, 40, 20, rl.BLACK)
}
