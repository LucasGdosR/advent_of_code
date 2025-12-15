package main

import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

Packet :: union #no_nil{ int, []Packet }
InOrder :: enum { UNDEFINED, NO, YES }

solve :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)

    it := string(input)
    idx, d2idx, d6idx := 1, 1, 2
    d2 := []Packet{[]Packet{2}}
    d6 := []Packet{[]Packet{6}}
    part1: int
    for left in strings.split_lines_iterator(&it)
    {
        defer free_all(context.temp_allocator)
        right, _ := strings.split_lines_iterator(&it)
        p1, _ := parse_packet(left)
        p2, _ := parse_packet(right)
        if is_in_order(p1, p2) == InOrder.YES do part1 += idx
        if is_in_order(p1, d2) == InOrder.YES do d2idx += 1
        if is_in_order(p2, d2) == InOrder.YES do d2idx += 1
        if is_in_order(p1, d6) == InOrder.YES do d6idx += 1
        if is_in_order(p2, d6) == InOrder.YES do d6idx += 1
        // Skip blank line
        strings.split_lines_iterator(&it)
        idx += 1
    }
    fmt.println(part1, d2idx * d6idx)
}


is_in_order :: proc(p1, p2: Packet) -> (in_order: InOrder)
{
    n1, ok1 := p1.(int)
    n2, ok2 := p2.(int)

    // both are numbers
    if ok1 && ok2 do in_order = n1 < n2 ? .YES : n1 > n2 ? .NO : .UNDEFINED
    // p2 is a list
    else if ok1 do in_order = is_in_order([]Packet{p1}, p2)
    // p1 is a list
    else if ok2 do in_order = is_in_order(p1, []Packet{p2})
    else // both are lists
    {
        p1 := p1.([]Packet)
        p2 := p2.([]Packet)

        // If both are empty, it's undefined.
        if len(p1) != 0 || len(p2) != 0
        {
            in_order = len(p1) == 0 ? .YES : len(p2) == 0 ? .NO : is_in_order(p1[0], p2[0])
            if in_order == .UNDEFINED do in_order = is_in_order(p1[1:], p2[1:])
        }
    }
    return
}

parse_packet :: proc(s: string) -> (p: Packet, idx: int)
{
    // This is a list:
    if s[0] == '['
    {
        list := make([dynamic]Packet, context.temp_allocator)
        idx = 1
        loop: for idx < len(s) do switch s[idx]
        {
            // The list is over:
            case ']':
                idx += 1
                p = list[:]
                break loop
            // Skip commas:
            case ',': idx += 1
            // Add a new element:
            case:
                sub_packet, i_inc := parse_packet(s[idx:])
                append(&list, sub_packet)
                idx += i_inc
        }
    }
    else do for i in 0..<len(s) // This is a number:
    {
        next := s[i]
        if next >= '0' && next <= '9' do p = p.(int) * 10 + int(next - '0')
        else { idx = i; break }
    }
    return
}

state :: struct {
    p1, p2: Packet,
    p1str, p2str, order_str: cstring,
    idx: int,
    input: string,
    is_done: bool,
    in_order: InOrder,
}

W :: 1800
H :: 190
X_PADDING :: 50
Y_PADDING :: 50
OFFSET :: 25
main :: proc()
{
    s: state
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)
    s.input = string(input)
    advance(&s)

rl.InitWindow(W, H, "AoC 2022.13")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose()
    {
        rl.BeginDrawing()
            rl.ClearBackground(rl.BLACK)
            rl.DrawText(s.p1str, X_PADDING, Y_PADDING, 18, rl.WHITE)
            rl.DrawText(s.p2str, X_PADDING, Y_PADDING + OFFSET, 18, rl.WHITE)
            rl.DrawText(s.order_str, X_PADDING, Y_PADDING + 2 * OFFSET, 20, s.in_order == .YES ? rl.GREEN : rl.RED)
        rl.EndDrawing()
        if !s.is_done && rl.IsKeyPressed(.SPACE) do advance(&s)
    }
}

advance :: proc(s: ^state)
{
    free_all(context.temp_allocator)
    left, _ := strings.split_lines_iterator(&s.input)
    right, _ := strings.split_lines_iterator(&s.input)
    _, ok := strings.split_lines_iterator(&s.input)
    s.is_done = !ok
    s.p1, _ = parse_packet(left)
    s.p2, _ = parse_packet(right)
    s.p1str = fmt.ctprint(s.p1)
    s.p2str = fmt.ctprint(s.p2)
    find_different_index(s)
}

find_different_index :: proc(s: ^state)
{
    helper :: proc(p1, p2: Packet, i: int) -> (idx: int, in_order: InOrder) {
        n1, ok1 := p1.(int)
        n2, ok2 := p2.(int)

        // both are numbers
        if ok1 && ok2
        {
            in_order = n1 < n2 ? .YES : n1 > n2 ? .NO : .UNDEFINED
            idx = i + 1
        }
        else if ok1 do idx, in_order = helper([]Packet{p1}, p2, i) // p2 is a list
        else if ok2 do idx, in_order = helper(p1, []Packet{p2}, i) // p1 is a list
        else // both are lists
        {
            p1 := p1.([]Packet)
            p2 := p2.([]Packet)

            // If both are empty, it's undefined.
            if len(p1) != 0 || len(p2) != 0
            {
                idx = i + 1
                if len(p1) == 0 do in_order = .YES
                else if len(p2) == 0 do in_order = .NO
                else do idx, in_order = helper(p1[0], p2[0], i)
                if in_order == .UNDEFINED do idx, in_order = helper(p1[1:], p2[1:], idx)
            }
            else do idx = i
        }
        return
    }

    idx, in_order := helper(s.p1, s.p2, 0)
    s.idx = idx
    s.in_order = in_order
    s.order_str = fmt.ctprint("Different at index", s.idx - 1, s.in_order == .YES ? "\nResult: in order." : "\nResult: out of order.")
}