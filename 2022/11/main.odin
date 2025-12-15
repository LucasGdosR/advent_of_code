package main

import "core:math"
import rl "vendor:raylib"
import "core:sort"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

MONKEYS :: 8
ALL_ITEMS :: 36

Monkey :: struct {
    items: [dynamic]int,
    op: byte,
    operand: int,
    test: int,
    consequent: int,
    alternative: int,
    inspection_count: int,
}


solve :: proc()
{
    monkeys_p1: [MONKEYS]Monkey
    all_tests_lcm := parse_input(monkeys_p1[:])
    // Make an immutable copy for part 2
    monkeys_p2 := monkeys_p1
    for m in 0..<MONKEYS
    {
        m1_items := monkeys_p1[m].items[:]
        items := make([dynamic]int, len(m1_items), ALL_ITEMS, context.temp_allocator)
        copy(items[:], m1_items)
        monkeys_p2[m].items = items
    }

    /*
     * Solve part 1
     */
    for round in 0..<20 do for &monkey in monkeys_p1 do for len(monkey.items) != 0
    {
        worry_level := pop(&monkey.items)
        amplified_worry_level := operation(monkey, worry_level)
        bored_worry_level := amplified_worry_level / 3
        append(&monkeys_p1[bored_worry_level % monkey.test == 0 ? monkey.consequent : monkey.alternative].items, bored_worry_level)
        monkey.inspection_count += 1
    }
    sort_monkeys(monkeys_p1[:])
    fmt.println(monkeys_p1[MONKEYS - 1].inspection_count * monkeys_p1[MONKEYS - 2].inspection_count)
    free_all(context.allocator)

    /*
     * Solve part 2
     */
    for round in 0..<10_000 do for &monkey in monkeys_p2 do for len(monkey.items) != 0
    {
        worry_level := pop(&monkey.items)
        amplified_worry_level := operation(monkey, worry_level)
        bored_worry_level := amplified_worry_level % all_tests_lcm
        append(&monkeys_p2[bored_worry_level % monkey.test == 0 ? monkey.consequent : monkey.alternative].items, bored_worry_level)
        monkey.inspection_count += 1
    }
    sort_monkeys(monkeys_p2[:])
    fmt.println(monkeys_p2[MONKEYS - 1].inspection_count * monkeys_p2[MONKEYS - 2].inspection_count)
}

operation :: proc(monkey: Monkey, old: int) -> int
{
    operand := monkey.operand
    if operand == 0 do operand = old
    return monkey.op == '*' ? old * operand : old + operand
}

sort_monkeys :: proc(monkeys: []Monkey)
{
    sort.quick_sort_proc(monkeys, proc(m1, m2: Monkey) -> int {
        if m1.inspection_count < m2.inspection_count do return -1
        else if m1.inspection_count > m2.inspection_count do return 1
        else do return 0
    })
}

parse_input :: proc(monkeys: []Monkey) -> int
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)

    it := string(input)
    all_tests_lcm := 1
    for i in 0..<MONKEYS
    {
        strings.split_lines_iterator(&it) // Monkey i:

        starting_items, _ := strings.split_lines_iterator(&it) // Starting items:
        for item in strings.split(starting_items[18:], ", ", context.temp_allocator)
        {
            initial_worry, _ := strconv.parse_int(item, 10)
            append(&monkeys[i].items, initial_worry)
        }

        operation, _ := strings.split_lines_iterator(&it) // Operation: new = old op operand
        monkeys[i].op = operation[23]
        operand, ok := strconv.parse_int(operation[25:])
        if ok do monkeys[i].operand = operand

        test, _ := strings.split_lines_iterator(&it) // Test: divisible by C
        divisor, _ := strconv.parse_int(test[21:])
        all_tests_lcm *= divisor
        monkeys[i].test = divisor

        consequent, _ := strings.split_lines_iterator(&it) // If true: throw to monkey x
        monkeys[i].consequent = int(consequent[29] - '0')

        alternative, _ := strings.split_lines_iterator(&it) // If false: throw to monkey y
        monkeys[i].alternative = int(alternative[30] - '0')

        strings.split_lines_iterator(&it) // <blank>
    }
    free_all(context.temp_allocator)
    return all_tests_lcm
}

/*
 * Visualization:
 * Display all monkeys and their items,
 * the operation being done,
 * the result of the test,
 * and the item being thrown to the consequent or alternative.
 */

State :: enum {
    HIGHLIGHT_ITEM,               // Highlight the item under consideration
    PERFORM_OPERATION_AND_DIVIDE, // Write out the operation and its result
    PERFORM_TEST,                 // Write out the test, its result, and target monkey
    ITEM_IN_MOTION,               // Throw the item to the monkey and block advancing
}

state :: struct {
    monkeys: [MONKEYS]Monkey,
    curr_monkey: int,
    curr_target: int,
    animation_frame_count: int,
    curr_amplified_worry_level: int,
    curr_bored_worry_level: int,
    state: State,
}

W :: 1900
H :: 1000
FPS :: 60
ANIMATION_IN_SECONDS :: 0.2
X_PADDING :: 450
Y_PADDING :: 100
W_MID :: W/2 - X_PADDING + 20
H_MID :: H/2 - Y_PADDING/2
X_OFFSET :: W/2 - X_PADDING
Y_OFFSET :: H/2 - Y_PADDING
FONT_SIZE :: 20
OFFSET := math.to_radians_f32(3)

main :: proc()
{
    s: state
    parse_input(s.monkeys[:])

    rl.InitWindow(W, H, "AoC 2022.11")
    defer rl.CloseWindow()
    rl.SetTargetFPS(FPS)
    for !rl.WindowShouldClose()
    {
        defer free_all(context.temp_allocator)
        curr_monkey := &s.monkeys[s.curr_monkey]

        // Advance simulation and state
        if rl.IsKeyPressed(.SPACE)
        {
            if s.state == .HIGHLIGHT_ITEM do s.curr_amplified_worry_level = operation(curr_monkey^, curr_monkey.items[0])
            if s.state == .PERFORM_OPERATION_AND_DIVIDE
            {
                s.curr_bored_worry_level = s.curr_amplified_worry_level / 3
                s.curr_target = s.curr_bored_worry_level % curr_monkey.test == 0 ? curr_monkey.consequent : curr_monkey.alternative
            }
            // Block manual advancing in ITEM_IN_MOTION
            if s.state != .ITEM_IN_MOTION do s.state = State(u8(s.state) + 1)
        }
        if s.state == .ITEM_IN_MOTION do s.animation_frame_count += 1

        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            draw_monkeys(s)

            sin, cos := math.sincos(2 * math.PI * f32(s.curr_monkey) / MONKEYS + OFFSET)
            pos_y := i32(H_MID + Y_OFFSET * sin + Y_PADDING/4 + FONT_SIZE)
            pos_x := i32(W_MID + X_OFFSET * cos)
            _PADDING :: 2
            BRACKET :: 5
            switch s.state
            {
                case .PERFORM_TEST:
                    divisible := s.curr_bored_worry_level % curr_monkey.test == 0
                    rl.DrawText(rl.TextFormat(
                        "%v is %vdivisible by %v.\nTarget: %v", s.curr_bored_worry_level, divisible ? "": "NOT ", curr_monkey.test, s.curr_target),
                        pos_x, pos_y + 2 * (FONT_SIZE + _PADDING), FONT_SIZE, rl.WHITE
                    )
                    fallthrough
                case .PERFORM_OPERATION_AND_DIVIDE:
                    rl.DrawText(rl.TextFormat(
                        "%v = %v %c %v", s.curr_amplified_worry_level, curr_monkey.items[0], curr_monkey.op, curr_monkey.operand),
                        pos_x, pos_y + FONT_SIZE + _PADDING, FONT_SIZE, rl.WHITE
                    )
                    fallthrough
                case .HIGHLIGHT_ITEM:
                    item_str_len := f32(len(fmt.tprint(curr_monkey.items[0])))
                    NUM_APPROX_WIDTH :: 12
                    rl.DrawLine(pos_x + BRACKET, pos_y + _PADDING, pos_x + i32(item_str_len * NUM_APPROX_WIDTH) + BRACKET, pos_y + _PADDING, rl.GOLD)

                case .ITEM_IN_MOTION:
                    sin_tar, cos_tar := math.sincos(2 * math.PI * f32(s.curr_target) / MONKEYS + OFFSET)

                    start := [2]f32{ f32(pos_x + BRACKET), f32(pos_y + 2 * (FONT_SIZE + _PADDING)) }

                    array_str_len := f32(len(fmt.tprint(s.monkeys[s.curr_target].items))) + 1
                    CHAR_APPROX_WIDTH :: 9.5
                    end: [2]f32
                    end.x = W_MID + X_OFFSET * cos_tar + CHAR_APPROX_WIDTH * array_str_len
                    end.y = H_MID + Y_OFFSET * sin_tar + Y_PADDING/4

                    this_pos := math.lerp(start, end, math.smoothstep(f32(0), f32(1), f32(s.animation_frame_count) / (FPS * ANIMATION_IN_SECONDS)))
                    rl.DrawText(fmt.ctprint(s.curr_bored_worry_level), i32(this_pos.x), i32(this_pos.y), 20, rl.WHITE)
            }
        rl.EndDrawing()

        // Advance the simulation to the next item, and possibly next monkey.
        if s.animation_frame_count == int(FPS * ANIMATION_IN_SECONDS)
        {
            // Side effects
            pop_front(&s.monkeys[s.curr_monkey].items)
            append(&s.monkeys[s.curr_target].items, s.curr_bored_worry_level)
            s.monkeys[s.curr_monkey].inspection_count += 1

            // Advance monkey
            for len(s.monkeys[s.curr_monkey].items) == 0 do s.curr_monkey = (s.curr_monkey + 1) % MONKEYS

            // Reset state
            s.state = .HIGHLIGHT_ITEM
            s.animation_frame_count = 0
        }
    }
}

draw_monkeys :: proc(s: state)
{
    // Position monkeys like clock positions
    for i in 0..<MONKEYS
    {
        sin, cos := math.sincos(2 * math.PI * f32(i) / MONKEYS + OFFSET)
        // Monkey
        rl.DrawText(rl.TextFormat("Monkey %v; Count: %v", i, s.monkeys[i].inspection_count), i32(W_MID + X_OFFSET * cos), i32(H_MID + Y_OFFSET * sin), FONT_SIZE, rl.WHITE)
        // Items
        rl.DrawText(fmt.ctprint(s.monkeys[i].items), i32(W_MID + X_OFFSET * cos), i32(H_MID + Y_OFFSET * sin + Y_PADDING/4), FONT_SIZE, rl.WHITE)
    }
}