package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"

solve :: proc()
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)
    defer free_all(context.temp_allocator)

    p1, p2: int
    for i in 0..=len(input) / 4
    {
        opponent := input[i*4]
        
        // Part 1
        played := input[i*4 + 2]
        p1 += int(played - 'W')
        if (played - opponent == 'Y' - 'A') || (opponent == 'C' && played == 'X') do p1 += 6
        else if (played - opponent == 'X' - 'A') do p1 += 3

        // Part 2
        p2 += 3 * int(played - 'X')
        if (opponent == 'A' && played == 'X') || (opponent == 'B' && played == 'Z') || (opponent == 'C' && played == 'Y') do p2 += 3
        else if (opponent == 'A' && played == 'Y') || (opponent == 'B' && played == 'X') || (opponent == 'C' && played == 'Z') do p2 += 1
        else do p2 += 2
    }
    fmt.println(p1, p2)
}

/**
 * Visualization ideas:
 * For debugging, the ideal would be to print each option chosen by each player
 * and whether it led to a loss, draw, or win. That's not fun to look at, though.
 * A more interesting visualization is to show the aggregate stats in bars.
 * There should be bars showing the number of wins, draws, and losses,
 * and also the spread of plays of each option (rock / paper / scissors).
 *
 * Making this multi-threaded is trivial, as each match is independent. Therefore,
 * I'm not going to bother doing that.
 */
W :: 1900
H :: 1000

Statistics :: enum { w1, d1, l1, w2, d2, l2, r1, p1, s1, r2, p2, s2, }

main :: proc()
{
    input, ok := os.read_entire_file("input", context.temp_allocator)
    if !ok do os.exit(1)
    
    S : [Statistics]i32
    i: i32
    fully_solved: bool
    end := i32(len(input)) / 4
    p1, p2: i32

    text : [Statistics]cstring = {
        .w1="W1 %d",
        .d1="D1 %d",
        .l1="L1 %d",
        .w2="W2 %d",
        .d2="D2 %d",
        .l2="L2 %d",
        .r1="R1 %d",
        .p1="P1 %d",
        .s1="S1 %d",
        .r2="R2 %d",
        .p2="P2 %d",
        .s2="S2 %d",
    }
        
    color : [Statistics]rl.Color = {
        .w1=rl.RED,
        .d1=rl.GREEN,
        .l1=rl.BLUE,
        .w2=rl.RED,
        .d2=rl.GREEN,
        .l2=rl.BLUE,
        .r1=rl.RED,
        .p1=rl.GREEN,
        .s1=rl.BLUE,
        .r2=rl.RED,
        .p2=rl.GREEN,
        .s2=rl.BLUE,
    }

    rl.InitWindow(W, H, "AoC 22/02")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    for !rl.WindowShouldClose()
    {
        if !fully_solved
        {
            for j := 0; i < end && j < 5; j += 1
            {
                o := input[i * 4]
                p := input[i * 4 + 2]
                
                // Part 1 choice
                if p == 'X' do S[.r1] += 1
                else if p == 'Y' do S[.p1] += 1
                else do S[.s1] += 1
                
                // Part 1 outcome
                if (p - o == 'Y' - 'A') || (o == 'C' && p == 'X') do S[.w1] += 1
                else if (p - o == 'X' - 'A') do S[.d1] += 1
                else do S[.l1] += 1
                
                // Part 2 choice
                if (o == 'A' && p == 'X') || (o == 'B' && p == 'Z') || (o == 'C' && p == 'Y') do S[.s2] += 1
                else if (o == 'A' && p == 'Y') || (o == 'B' && p == 'X') || (o == 'C' && p == 'Z') do S[.r2] += 1
                else do S[.p2] += 1
                
                // Part 2 outcome
                if p == 'X' do S[.l2] += 1
                else if p == 'Y' do S[.d2] += 1
                else do S[.w2] += 1
                
                i += 1
            }
            if i == end
            {
                free_all(context.temp_allocator)
                p1 = S[.w1] * 6 + S[.d1] * 3 + S[.s1] * 3 + S[.p1] * 2 + S[.r1]
                p2 = S[.w2] * 6 + S[.d2] * 3 + S[.s2] * 3 + S[.p2] * 2 + S[.r2]
                fully_solved = true
            }
        }
        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)
            /*
vpad    -
cell_h  hpad    cell    cell    cell    hspacing    cell    cell    cell    hpad
vspacing-
cell_h  hpad    cell    cell    cell    hspacing    cell    cell    cell    hpad
vpad
            */
            ROWS :: 2
            COLS :: 6
            hpad :: W/3
            vpad :: H/8
            hspacing :: (W - 2*hpad) / (COLS+1) // cell_w == hspacing
            vspacing :: (H - 2*vpad) / (2*ROWS + 2)
            cell_h :: (H - 2*vpad - vspacing) / ROWS
            for s, e in S
            {
                i := i32(e)
                row := i / COLS
                col := i % COLS
                this_h := s / 5
                this_y := vpad + cell_h + (row >= ROWS/2 ? (vspacing + cell_h) : 0) - this_h
                this_x := hpad + col * hspacing + (col >= COLS/2 ? hspacing : 0)
                rec : rl.Rectangle = { f32(this_x), f32(this_y), hspacing, f32(this_h) }
                rl.DrawRectangleRec(rec, color[e])
                rl.DrawText(rl.TextFormat(text[e], s), this_x + 10, this_y - 30, 20, rl.RAYWHITE)
            }

            if fully_solved
            {
                rec: rl.Rectangle = { W/2 - 240, H/2 - 50, 480, 100 }
                rl.DrawRectangleRec(rec, rl.BLACK)
                rl.DrawRectangleLinesEx(rec, 2, rl.LIME)
                rl.DrawText(rl.TextFormat("Part 1 solution: %d\nPart 2 solution: %d", p1, p2),
                    W/2 - 230, H/2 - 40, 40, rl.LIME)
            }
    }
}