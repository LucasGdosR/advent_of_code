package main

import rl "vendor:raylib"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

INPUT_HEIGHT :: 8
NUM_OF_STACKS :: 9
Stack :: struct($T: typeid) {
    size: int,
    data: [INPUT_HEIGHT * NUM_OF_STACKS]T
}
solve :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    defer delete(input)
    it := string(input)

    stacks, goku_stacks: [NUM_OF_STACKS]Stack(byte)
    read_stacks(&it, &stacks, &goku_stacks)

    // Skip two lines
    strings.split_lines_iterator(&it)
    strings.split_lines_iterator(&it)

    // Read moves
    for line in strings.split_lines_iterator(&it)
    {
        line := line
        // Skip "move"
        strings.fields_iterator(&line)
        // Amount to move
        amt_str, _ := strings.fields_iterator(&line)
        amount := strconv.atoi(amt_str)
        // Skip "from"
        strings.fields_iterator(&line)
        // Source
        src_str, _ := strings.fields_iterator(&line)
        src := strconv.atoi(src_str)
        // Skip "to"
        strings.fields_iterator(&line)
        // Destination
        dst_str, _ := strings.fields_iterator(&line)
        dst := strconv.atoi(dst_str)
        
        s, d := &goku_stacks[src-1], &goku_stacks[dst-1]
        for i in 0..<amount
        {
            push(&stacks[dst-1], pop(&stacks[src-1]))
            d.data[d.size+i] = s.data[s.size - amount + i]
        }
        s.size -= amount
        d.size += amount
    }

    p1, p2: [NUM_OF_STACKS]byte
    for i in 0..<NUM_OF_STACKS
    {
        p1[i] = stacks[i].data[stacks[i].size - 1]
        p2[i] = goku_stacks[i].data[goku_stacks[i].size - 1]
    }

    fmt.println(string(p1[:]))
    fmt.println(string(p2[:]))
}

read_stacks :: proc(it: ^string, stacks, goku_stacks: ^[NUM_OF_STACKS]Stack($T))
{
    for i in 0..<INPUT_HEIGHT
    {
        line, _ := strings.split_lines_iterator(it)
        for j in 0..<NUM_OF_STACKS
        {
            if line[4*j + 1] != ' '
            {
                stacks[j].size += 1
                goku_stacks[j].size += 1
                when T == u8
                {
                    stacks[j].data[INPUT_HEIGHT - 1 - i] = line[4*j + 1]
                    goku_stacks[j].data[INPUT_HEIGHT - 1 - i] = line[4*j + 1]
                }
                when T == Stack_State
                {
                    stacks[j].data[INPUT_HEIGHT - 1 - i].char = line[4*j + 1]
                    goku_stacks[j].data[INPUT_HEIGHT - 1 - i].char = line[4*j + 1]
                }
            }
        }
    }
}

push :: proc(stack: ^Stack($T), char: T)
{
    stack.data[stack.size] = char
    stack.size += 1
}

pop :: proc(stack: ^Stack($T)) -> T
{
    stack.size -= 1
    return stack.data[stack.size]
}

/*
 * Visualization:
 * Draw stacks for each machine on either side of the screen.
 * Write the current move. Highlight the stacks that should pop / push.
 * Animate the transition.
 */

W :: 1900
H :: 1000
State :: enum { READ_INPUT, MOVE_STACKS, ANIMATE_MOVE, FULLY_SOLVED }
Stack_State :: struct {
    char: byte,
    prev_xy: [2]f32,
}
main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    it := string(input)

    stacks, goku_stacks: [NUM_OF_STACKS]Stack(Stack_State)
    read_stacks(&it, &stacks, &goku_stacks)
    init_stacks(&stacks, 0)
    init_stacks(&goku_stacks, 1)

    strings.split_lines_iterator(&it)
    strings.split_lines_iterator(&it)

    frame_count, amount, src, dst: int
    // Init amount, src, dst
    {
        line, _ := strings.split_lines_iterator(&it)
        strings.fields_iterator(&line) // Skip "move"
        amt_str, _ := strings.fields_iterator(&line) // Amount to move
        amount = strconv.atoi(amt_str)
        strings.fields_iterator(&line) // Skip "from"
        src_str, _ := strings.fields_iterator(&line) // Source
        src = strconv.atoi(src_str)
        strings.fields_iterator(&line) // Skip "to"
        dst_str, _ := strings.fields_iterator(&line) // Destination
        dst = strconv.atoi(dst_str)
    }
    state : State = .MOVE_STACKS
    
    rl.InitWindow(W, H, "AoC 22.05")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)
    
    for !rl.WindowShouldClose()
    {
        if rl.IsKeyPressed(.SPACE)
        {
            switch state {
                case .READ_INPUT:
                    if line, ok := strings.split_lines_iterator(&it); ok
                    {
                        strings.fields_iterator(&line) // Skip "move"
                        amt_str, _ := strings.fields_iterator(&line) // Amount to move
                        amount = strconv.atoi(amt_str)
                        strings.fields_iterator(&line) // Skip "from"
                        src_str, _ := strings.fields_iterator(&line) // Source
                        src = strconv.atoi(src_str)
                        strings.fields_iterator(&line) // Skip "to"
                        dst_str, _ := strings.fields_iterator(&line) // Destination
                        dst = strconv.atoi(dst_str)
                        state = .MOVE_STACKS
                    }
                    else
                    {
                        state = .FULLY_SOLVED
                        delete(input)
                    }
                case .MOVE_STACKS:
                    s, d := &goku_stacks[src-1], &goku_stacks[dst-1]
                    for i in 0..<amount
                    {
                        push(&stacks[dst-1], pop(&stacks[src-1]))
                        d.data[d.size+i] = s.data[s.size - amount + i]
                    }
                    s.size -= amount
                    d.size += amount
                    state = .ANIMATE_MOVE
                case .ANIMATE_MOVE:
                case .FULLY_SOLVED:
            }
        }

        if state == .ANIMATE_MOVE do frame_count += 1
        defer if frame_count == 60
        {
            frame_count = 0
            state = .READ_INPUT
        }
        
        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.DrawText(rl.TextFormat("move %d from %d to %d", amount, src, dst), 100, 100, 20, rl.RED)
            draw_src_dst_framing(src)
            draw_src_dst_framing(dst)
            rl.DrawLine(W/2, 0, W/2, H, rl.GOLD)
            for i in i32(0)..<NUM_OF_STACKS
            {
                draw_stack(&stacks[i], i, 0, frame_count)
                draw_stack(&goku_stacks[i], i, 1, frame_count)
            }      
    }
}

X :: 100
Y :: 100
DX :: (W - 2*X) / (2*NUM_OF_STACKS - 1)
DY :: 2 * ((H - 2*Y) / (NUM_OF_STACKS * INPUT_HEIGHT - 1))
draw_stack :: proc(s: ^Stack(Stack_State), i, dx: i32, frame: int)
{
    posX := X + DX * (i + dx*NUM_OF_STACKS)
    rl.DrawText(rl.TextFormat("%d", i + 1), posX, H - Y + DY, 20, rl.RED)

    if frame == 60
    {
        f32posX := f32(posX)
        for j in 0..<i32(s.size)
        {
            posY := H - Y - j*DY
            s.data[j].prev_xy = { f32posX, f32(posY) }
            rl.DrawText(rl.TextFormat("%c", s.data[j].char), posX, posY, 15, rl.RAYWHITE)
        }
    }
    else if frame > 0
    {
        currX := f32(posX)
        normal_curr := f32(frame) / 60
        normal_prev : f32 = 1 - normal_curr
        for j in 0..<i32(s.size)
        {
            currY := f32(H - Y - j*DY)
            posX = i32(normal_curr * currX + normal_prev * s.data[j].prev_xy.x)
            posY := i32(normal_curr * currY + normal_prev * s.data[j].prev_xy.y)
            rl.DrawText(rl.TextFormat("%c", s.data[j].char), posX, posY, 15, rl.RAYWHITE)
        }
    }
    else
    {
        for j in 0..<i32(s.size) do rl.DrawText(rl.TextFormat("%c", s.data[j].char), posX, H - Y - j*DY, 15, rl.RAYWHITE)
    }
}

draw_src_dst_framing :: proc(i: int)
{
    posX := X + DX * i32(i - 1)
    rl.DrawRectangleLines(posX-5, H - Y + DY-2, 22, 22, rl.GOLD)
    rl.DrawRectangleLines(posX-5 + NUM_OF_STACKS * DX, H - Y + DY-2, 22, 22, rl.GOLD)
}

init_stacks :: proc(stacks: ^[NUM_OF_STACKS]Stack(Stack_State), dx: i32)
{
    // Misuse of already written code
    for &s, i in stacks do draw_stack(&s, i32(i), dx, 60)
}