package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strings"

Char_Set :: bit_set['A'..='z']

solve :: proc()
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)
    defer free_all(context.temp_allocator)
    
    p1, p2 : int
    it := string(input)
    for first_line in strings.split_lines_iterator(&it)
    {
        second_line, _ := strings.split_lines_iterator(&it)
        third_line, _ := strings.split_lines_iterator(&it)

        badge: Char_Set
        badge = process_line(first_line, &p1)
        badge &= process_line(second_line, &p1)
        badge &= process_line(third_line, &p1)
        for r in badge
        {
            p2 += get_priority(r)
            break
        }
    }
    fmt.println(p1, p2)
}

get_priority :: proc(r: rune) -> int
{
    return r <= 'Z' ? int(r - 'A' + 27) : int(r - 'a' + 1)
}

process_line :: proc(line: string, result: ^int) -> bit_set['A'..='z']
{
    first, second := line[:len(line)/2], line[len(line)/2:]
    set1, set2 : Char_Set
    for r in first do set1 += { r }
    for r in second do set2 += { r }
    for r in set1 & set2
    {
        result^ += get_priority(r)
        break
    }
    return set1+set2
}

/**
 * Visualization ideas:
 * Manual stepping makes sense in this case. A nice visualization would be to highlight
 * the repeating character in both halves of each line, and also to highlight the repeating
 * character in all three lines.
 *
 * To avoid a brute force (O(n²)) implementation, I chose to do multiple passes over the
 * string. The first pass on a half builds a set, the only pass on the second half finds
 * the repeating character, and then a second pass on the first half finds the index of the
 * repeating character. That's still O(n).
 *
 * For part 2 of the problem, the first pass on all strings finds the repeating character
 * by creating a set, and the second pass finds the index of the character in all strings.
 *
 * Making this multi-threaded is actually really hard. In order to chunk the work, we must
 * find multiple of 3 line breaks. Finding those requires scanning the whole input file
 * serially. Reading a byte depends on reading the previous byte. If we're going to read it,
 * might aswell process it and be done with it. Therefore, no multi-threading for this puzzle.
 *
 * Finishing touches: make a prettier layout and render the character->priority scale. Draw
 * frames around the relevant priority scores in every iteration.
 */
W :: 1900
H :: 1000
GROUP_SIZE :: 3
State_Machine :: enum { CAN_ADVANCE, ANIMATING, FULLY_SOLVED }
State :: struct
{
    state_machine: State_Machine,
    iterator: string,
    // Strings to display
    lines: [GROUP_SIZE]string,
    frame_count: int,
    p1, p2: u16,
    // Indexes into the string:
    // e.g.: first half of the first string
    // e.g.: badge index in the first string
    h1, h2, b: [GROUP_SIZE]u8,
}

main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    defer free_all(context.allocator)

    state: State = { iterator=string(input) }
    compute_iteration(&state)
    
    rl.InitWindow(W, H, "AoC 22.03")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose()
    {
        defer free_all(context.temp_allocator)
        if state.state_machine == .CAN_ADVANCE && rl.IsKeyDown(.SPACE) do compute_iteration(&state)
        else if state.state_machine == .ANIMATING
        {
            if state.frame_count == 210
            {
                state.frame_count = 0
                state.state_machine = .CAN_ADVANCE
            }
            else
            {
                state.frame_count += 1
            }
        }
        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)
            draw_priority_sum(state)
            if state.state_machine != .ANIMATING || state.frame_count >= 180 do draw_everything(state)
            else
            {
                if state.frame_count < 60 do draw_strings(state, 1)
                else if state.frame_count < 120 do draw_strings(state, 2)
                else do draw_strings(state, 3)
                if state.frame_count >= 150 do draw_frames_p1(state, 3)
                else if state.frame_count >= 90 do draw_frames_p1(state, 2)
                else if state.frame_count >= 30 do draw_frames_p1(state, 1)
            }
    }
}

compute_iteration :: proc(s: ^State)
{
    if line, ok := strings.split_lines_iterator(&s.iterator); ok
    {
        s.lines[0] = line
        s.lines[1], _ = strings.split_lines_iterator(&s.iterator)
        s.lines[2], _ = strings.split_lines_iterator(&s.iterator)
        
        charset, temp: Char_Set
        charset, s.h1[0], s.h2[0] = get_charset_and_idx_of_repeated_char_in_both_halves(s.lines[0])
        s.p1 += u16(get_priority(rune(s.lines[0][s.h1[0]])))
        for i in 1..<GROUP_SIZE
        {
            temp, s.h1[i], s.h2[i] = get_charset_and_idx_of_repeated_char_in_both_halves(s.lines[i])
            s.p1 += u16(get_priority(rune(s.lines[i][s.h1[i]])))
            charset &= temp
        }
        
        badge: rune
        for r in charset do badge = r
        for i in 0..<GROUP_SIZE do s.b[i] = u8(strings.index_rune(s.lines[i], badge))
        
        s.p2 += u16(get_priority(rune(s.lines[0][s.b[0]])))
        s.state_machine = .ANIMATING
    }
    else do s.state_machine = .FULLY_SOLVED
}

get_charset_and_idx_of_repeated_char_in_both_halves :: proc(s: string) -> (set: bit_set['A'..='z'], idx1, idx2: u8)
{
    h1, h2 := s[:len(s)/2], s[len(s)/2:]
    set1, set2: Char_Set
    for r in h1 do set1 += { r }
    for r, i in h2
    {
        set2 += { r }
        if r in set1 do idx2 = u8(i)
    }
    set = set1 + set2
    for r, i in h1
    {
        if r in set2
        {
            idx1 = u8(i)
            break
        }
    }
    return
}

draw_everything :: proc(s: State)
{
    draw_strings(s, 3)
    draw_frames_p1(s, 3)
    draw_frames_p2(s)
}

draw_strings :: proc(s: State, bound: int)
{
    y :: 100
    x :: 50
    for i in 0..<bound
    {
        i := i32(i)
        line := s.lines[i]
        // This allocates once for each character.
        // It sucks, but it was only the way to get a consistent spacing to draw frames around indexes.
        // I tried loading a monospaced font, but it didn't quite work.
        // Would definitely use monospaced font for a serious implementation.
        for r, j in line
        {
            char_str := fmt.tprintf("%c", r)
            rl.DrawText(strings.clone_to_cstring(char_str, context.temp_allocator), x + i32(j) * 20, y + i * 100, 20, rl.WHITE)
        }
        mid_x := x + i32(len(line)/2) * 20 - 5
        rl.DrawLine(mid_x, y - 10 + i * 100, mid_x, y + 30 + i * 100, rl.GRAY)
    }
}

draw_frames_p1 :: proc(s: State, bound: int)
{
    y :: 100
    x :: 45
    for i in 0..<bound
    {
        rect1 : rl.Rectangle = {
            x = f32(x + int(s.h1[i]) * 20),
            y = f32(y - 2 + 100 * i),
            width = 24,
            height = 24,
        }
        rl.DrawRectangleLinesEx(rect1, 2, rl.RED)
        rect2 : rl.Rectangle = {
            x = f32(x + (len(s.lines[i])/2 + int(s.h2[i])) * 20 - 2),
            y = f32(y - 2 + 100 * i),
            width = 24,
            height = 24,
        }
        rl.DrawRectangleLinesEx(rect2, 2, rl.RED)
    }
}

draw_frames_p2 :: proc(s: State)
{
    x :: 45
    for i in 0..<GROUP_SIZE
    {
        rect := rl.Rectangle{
            x = f32(x + int(s.b[i]) * 20),
            y = f32(100 - 2 + 100 * i),
            width = 24,
            height = 24,
        }
        rl.DrawRectangleLinesEx(rect, 3, rl.GOLD)
    }
}

draw_priority_sum :: proc(s: State)
{
    p1_text := fmt.tprintf("Part 1: %d", s.p1)
    rl.DrawText(strings.clone_to_cstring(p1_text, context.temp_allocator), 50, 20, 30, rl.LIME)
    
    p2_text := fmt.tprintf("Part 2: %d", s.p2)
    rl.DrawText(strings.clone_to_cstring(p2_text, context.temp_allocator), 300, 20, 30, rl.BLUE)
}