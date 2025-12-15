package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"

solve :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    defer delete(input)

    window := make_map_cap(map[byte]u8, 4)
    defer delete(window)
    window[input[0]] = 1
    insert_or_increment(&window, input[1])
    insert_or_increment(&window, input[2])

    for i in 3..<len(input)
    {
        insert_or_increment(&window, input[i])
        if len(window) == 4
        {
            fmt.println(i+1)
            break
        }
        decrement_or_delete(&window, input[i-3])
    }

    m := make_map_cap(map[byte]u8, 14)
    defer delete(m)
    for i in 0..<13 do insert_or_increment(&m, input[i])

    for i in 13..<len(input)
    {
        insert_or_increment(&m, input[i])
        if len(m) == 14
        {
            fmt.println(i+1)
            break
        }
        decrement_or_delete(&m, input[i-13])
    }
}

insert_or_increment :: proc(m: ^map[byte]u8, k: byte)
{
    if k not_in m do m[k] = 1
    else do m[k] += 1
}

decrement_or_delete :: proc(m: ^map[byte]u8, k: byte)
{
    if m[k] == 1 do delete_key(m, k)
    else do m[k] -= 1
}

/*
 * Visualization:
 * Have a fixed box for the substring inside the 4 and 14 windows.
 * Have the input scroll and highlight the repeated characters inside the windows.
 * Display the index somewhere.
 *
 * In order to highlight characters, check if their value in the map > 1.
 */
W :: 1900
H :: 300
State :: enum { SEEKING_BOTH, SEEKING_14, FOUND_BOTH }
main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    defer delete(input)

    map4 := make_map_cap(map[byte]u8, 4)
    map14 := make_map_cap(map[byte]u8, 14)
    i4, i14 := 3, 13
    state: State
    frame_count: int

    for i in 0..<3 do insert_or_increment(&map4, input[i])
    for i in 0..<13 do insert_or_increment(&map14, input[i])

    rl.InitWindow(W, H, "AoC 22.06")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose()
    {
        defer frame_count += 1
        if frame_count == 30
        {
            frame_count = 0
            switch state {
                case .SEEKING_BOTH:
                    insert_or_increment(&map4, input[i4])
                    insert_or_increment(&map14, input[i14])
                    if len(map4) == 4
                    {
                        state = .SEEKING_14
                        delete(map4)
                    }
                    else do decrement_or_delete(&map4, input[i4-3])
                    decrement_or_delete(&map14, input[i14-13])
                    i4 += 1
                    i14 += 1
                case .SEEKING_14:
                    insert_or_increment(&map14, input[i14])
                    if len(map14) == 14
                    {
                    state = .FOUND_BOTH
                    delete(map14)
                    }
                    else do decrement_or_delete(&map14, input[i14-13])
                    i14 += 1
                case .FOUND_BOTH:
                }
        }

        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)

            X :: 100
            Y :: 100
            DY :: 100
            DX :: 30
            FONT_SIZE :: 20
            REC_PADDING :: 3

            // Draw the boxes where the current window is rendered
            rl.DrawRectangleLines(X - REC_PADDING, Y - REC_PADDING, DX * 4 + REC_PADDING, FONT_SIZE + 2*REC_PADDING, rl.BLUE)
            rl.DrawRectangleLines(X - REC_PADDING, Y + DY - REC_PADDING, DX * 14 + REC_PADDING, FONT_SIZE + 2*REC_PADDING, rl.BLUE)

            animation_dx := DX * max(0, (f32(frame_count) - 15) / 15)
            animation_dx_p1, animation_dx_p2: f32
            switch state {
                case .SEEKING_BOTH:
                    animation_dx_p1 = animation_dx
                    animation_dx_p2 = animation_dx
                case .SEEKING_14:
                    animation_dx_p2 = animation_dx
                case .FOUND_BOTH:
            }

            // Draw visible characters
            for i in 0..<(W/DX + 2)
            {
                f := f32(i)
                rl.DrawTextCodepoint(rl.GetFontDefault(), rune(input[i4 + i - 3]), { X + f*DX - animation_dx_p1, Y }, FONT_SIZE, rl.RAYWHITE)
                rl.DrawTextCodepoint(rl.GetFontDefault(), rune(input[i14 + i - 13]), { X + f*DX - animation_dx_p2, Y+DY }, FONT_SIZE, rl.RAYWHITE)
            }

            // Draw rec on repeated characters of part 1
            for i in i32(0)..<4
            {
                // Workaround given the way state is mutated in main switch-statement
                if map4[input[i32(i4) + i - 3]] > 1 || (map4[input[i32(i4) + i - 3]] == 1 && input[i32(i4)] == input[i32(i4) + i - 3])
                {
                    rl.DrawRectangleLines(X + i*DX - i32(animation_dx_p1), Y, FONT_SIZE + 2*REC_PADDING, FONT_SIZE, rl.RED)
                }
            }
            // Draw rec on repeated characters of part 2
            for i in i32(0)..<14
            {
                if map14[input[i32(i14) + i - 13]] > 1 || (map14[input[i32(i14) + i - 13]] == 1 && input[i32(i14)] == input[i32(i14) + i - 13])
                {
                    rl.DrawRectangleLines(X + i*DX - i32(animation_dx_p2), Y+DY, FONT_SIZE + 2*REC_PADDING, FONT_SIZE, rl.RED)
                }
            }
            rl.DrawText(rl.TextFormat("%d", i4), 50, 50, 20, rl.GOLD)
            rl.DrawText(rl.TextFormat("%d", i14), 50, 250, 20, rl.GOLD)
    }
}