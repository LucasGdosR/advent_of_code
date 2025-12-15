package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"

TARGET_ROW :: 2000000
LINES_IN_FILE :: 24
LINES_PER_SENSOR :: 4
SENSOR :: 0
BEACON :: 1

W :: 1000
H :: W

Line :: struct { x, y, slope: int }

main :: proc()
{
    // Parsing:
    sensor_beacon_array: [LINES_IN_FILE][2][2]int
    sensor_beacon := sensor_beacon_array[:]
    parse_input(sensor_beacon)

    lines_array: [LINES_IN_FILE * 4]Line
    lines := lines_array[:]
    // Part 1:
    {
        intervals_array: [LINES_IN_FILE][2]int
        intervals := intervals_array[:]
        sbs_to_intervals_and_lines(sensor_beacon, intervals, lines)
        slice.sort_by(intervals, interval_sort)
        merged_intervals := merge_intervals_alloc(intervals)
        result := sum_intervals(merged_intervals) - sub_beacons(sensor_beacon, merged_intervals)
        free_all(context.temp_allocator) // Frees merged_intervals
        fmt.println("Part 1:", result)
    }

    // Part 2:
    free_point := find_free_point(lines, sensor_beacon)
    fmt.println("Part 2:", free_point.x * UPPER_BOUND + free_point.y)

    // Visualization
    rl.InitWindow(W, H, "AoC 2022.15")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        draw_sensor_radii(sensor_beacon)
        draw_lines(lines)
        draw_free_point(free_point)
    rl.EndDrawing()

    for !rl.WindowShouldClose()
    {
        // Allows closing the window
        rl.BeginDrawing()
        rl.EndDrawing()
    }
}

find_free_point :: proc(lines: []Line, sbs: [][2][2]int) -> (free_point: [2]int)
{
    for i in 0..<len(lines) do for j in i+1..<len(lines)
    {
        if lines[i].slope != lines[j].slope
        {
            intercept := find_intercept(lines[i], lines[j])
            if intercept.x >= LOWER_BOUND && intercept.x <= UPPER_BOUND &&
               intercept.y >= LOWER_BOUND && intercept.y <= UPPER_BOUND
            {
                is_free := true
                for sb in sbs
                {
                    dist := abs(intercept.x - sb[SENSOR].x) + abs(intercept.y - sb[SENSOR].y)
                    sensor_range := abs(sb[SENSOR].x - sb[BEACON].x) + abs(sb[SENSOR].y - sb[BEACON].y)
                    if dist <= sensor_range
                    {
                        is_free = false
                        break
                    }
                }
                if is_free do return intercept
            }
        }
    }
    return
}

find_intercept :: proc(a, b: Line) -> [2]int
{
    // For lines with opposite slopes (1 and -1):
    // Line a: y - a.y = a.slope * (x - a.x)
    // Line b: y - b.y = b.slope * (x - b.x)
    //
    // Solving for intersection:
    // a.slope * (x - a.x) + a.y = b.slope * (x - b.x) + b.y

    dx := (b.y - a.y + a.slope * a.x - b.slope * b.x) / (a.slope - b.slope)
    dy := a.slope * (dx - a.x) + a.y

    return { dx, dy }
}

sbs_to_intervals_and_lines :: proc(sbs: [][2][2]int, intervals: [][2]int, lines: []Line)
{
    for &sb, i in sbs
    {
        manhattan_distance := abs(sb[SENSOR].x - sb[BEACON].x) + abs(sb[SENSOR].y - sb[BEACON].y)
        sensor_to_target := abs(TARGET_ROW - sb[SENSOR].y)
        interval_length := manhattan_distance - sensor_to_target
        intervals[i] = { sb[SENSOR].x - interval_length, sb[SENSOR].x + interval_length }

        dx := manhattan_distance + 1
        lines_idx := LINES_PER_SENSOR * i
        lines[lines_idx] = Line { x=sb[SENSOR].x + dx, y=sb[SENSOR].y, slope=1}
        lines[lines_idx + 1] = Line { x=sb[SENSOR].x + dx, y=sb[SENSOR].y, slope=-1}
        lines[lines_idx + 2] = Line { x=sb[SENSOR].x - dx, y=sb[SENSOR].y, slope=1}
        lines[lines_idx + 3] = Line { x=sb[SENSOR].x - dx, y=sb[SENSOR].y, slope=-1}
    }
}

merge_intervals_alloc :: proc(intervals: [][2]int) -> [][2]int
{
    merged_intervals := make([dynamic][2]int, 0, LINES_IN_FILE, context.temp_allocator)
    curr := [2]int{ 0, -1 }
    for i in intervals
    {
        if i[0] <= i[1] // Filter negative intervals
        {
            // Init curr to the first non-negative interval
            if curr[1] < curr[0] do curr = i
            if i[0] <= curr[1] do curr[1] = max(curr[1], i[1])
            else
            {
                append(&merged_intervals, curr)
                curr = i
            }
        }
    }
    append(&merged_intervals, curr)
    return merged_intervals[:]
}

sum_intervals :: proc(intervals: [][2]int) -> int
{
    result: int
    for i in intervals do result += i[1] - i[0] + 1
    return result
}

sub_beacons :: proc(sbs: [][2][2]int, intervals: [][2]int) -> int
{
    placed_beacons := make([dynamic]int, context.temp_allocator)
    for sb in sbs
    {
        b := sb[BEACON]
        if b.y == TARGET_ROW && !slice.contains(placed_beacons[:], b.x) && is_in_some_interval(intervals, b.x) do append(&placed_beacons, b.x)
    }
    return len(placed_beacons)
}

is_in_some_interval :: proc(intervals: [][2]int, x: int) -> bool
{
    return true
}

parse_input :: proc(sensor_beacon: [][2][2]int)
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)

    it := string(input)
    i: int
    for line in strings.split_lines_iterator(&it)
    {
        sx := line[12:]
        sx_end := strings.index_byte(sx, ',')
        a, _ := strconv.parse_int(sx[:sx_end])

        sy := sx[sx_end+4:]
        sy_end := strings.index_byte(sy, ':')
        b, _ := strconv.parse_int(sy[:sy_end])

        bx := sy[sy_end+25:]
        bx_end := strings.index_byte(bx, ',')
        c, _ := strconv.parse_int(bx[:bx_end])

        by := bx[bx_end+4:]
        d, _ := strconv.parse_int(by)

        sensor_beacon[i] = [2][2]int{{a, b}, {c, d}}
        i += 1
    }
    free_all(context.temp_allocator)
}

interval_sort :: proc(i, j: [2]int) -> bool
{
    return i[0] < j[0]
}

LOWER_BOUND :: 0
UPPER_BOUND :: 4_000_000
draw_sensor_radii :: proc(sbs: [][2][2]int)
{
    font := rl.GetFontDefault()

    for sb, i in sbs
    {
        color := rl.ColorFromHSV(f32(i * 360) / LINES_IN_FILE, 0.8, 0.9)
        x := int_to_screen(sb[SENSOR].x)
        y := int_to_screen(sb[SENSOR].y)
        manhattan_distance := abs(sb[SENSOR].x - sb[BEACON].x) + abs(sb[SENSOR].y - sb[BEACON].y)
        delta := f32(manhattan_distance * W) / (UPPER_BOUND - LOWER_BOUND)
        rl.DrawPoly({x, y}, 4, delta-7, rl.PI / 4, color)
        rl.DrawTextCodepoint(font, rune('0' + i / 10), { x-10, y }, 15, rl.WHITE)
        rl.DrawTextCodepoint(font, rune('0' + i % 10), { x, y }, 15, rl.WHITE)
    }
}

draw_lines :: proc(lines: []Line)
{
    for line in lines
    {
        dx_left := min(line.x, line.slope == 1 ? line.y : UPPER_BOUND - line.y)
        dx_right := min(UPPER_BOUND - line.x, line.slope == -1 ? line.y : UPPER_BOUND - line.y)
        left := [2]f32{ int_to_screen(line.x - dx_left), int_to_screen(line.y - dx_left * line.slope) }
        right := [2]f32{ int_to_screen(line.x + dx_right), int_to_screen(line.y + dx_right * line.slope)}
        // Lines only intersect if they're the same color
        rl.DrawLineEx(left, right, 2.0, (line.x + line.y) & 1 == 0 ? rl.WHITE : rl.BLACK)
    }
}

draw_free_point :: proc(free_point: [2]int)
{
    x := int_to_screen(free_point.x)
    y := int_to_screen(free_point.y)
    rl.DrawCircleV({x, y}, 5, rl.RED)
}

int_to_screen :: proc(i: int) -> f32
{
    return f32((i - LOWER_BOUND) * W) / (UPPER_BOUND - LOWER_BOUND)
}