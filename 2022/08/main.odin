package main

import "core:debug/trace"
import "core:debug/pe"
import rl "vendor:raylib"
import "core:fmt"
import "core:os"

GRID_SIDE :: 99
LINE_BREAK :: 1

Directions :: enum { L, R, U, D }
// Visibility :: enum { INVISIBLE=0b00, OUTSIDE=0b01, INSIDE=0b10, BOTH=0b11 }
ViewMode :: enum { P1, P2 }

main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)

    grid := cast(^[GRID_SIDE][GRID_SIDE+LINE_BREAK]u8)raw_data(input)
    visible: [GRID_SIDE][GRID_SIDE]u8

    for i in 0..<GRID_SIDE
    {
        max_height: [Directions]u8
        for j in 0..<GRID_SIDE
        {
            for d in Directions
            {
                x, y: int
                switch d
                {
                    case .L: x, y = i, j
                    case .R: x, y = i, GRID_SIDE - 1 - j
                    case .U: x, y = j, i
                    case .D: x, y = GRID_SIDE - 1 - j, i
                }
                tree_height := grid[x][y]
                tree_visible := u8(tree_height > max_height[d])
                visible[x][y] |= tree_visible
                if bool(tree_visible) do max_height[d] = tree_height
            }
        }
    }

    seen, max_scenic_score, max_i, max_j: int
    for i in 0..<GRID_SIDE do for j in 0..<GRID_SIDE do if bool(visible[i][j])
    {
        seen += 1
        this_scenic_score := 1
        this_height := grid[i][j]
        for d in Directions
        {
            di, dj, this_d_score: int
            switch d
            {
                case .L: di, dj =  0, -1
                case .R: di, dj =  0,  1
                case .U: di, dj = -1,  0
                case .D: di, dj =  1,  0
            }
            i, j := i+di, j+dj
            for
            {
                if i >= 0 && i < GRID_SIDE && j >= 0 && j < GRID_SIDE
                {
                    this_d_score += 1
                    if grid[i][j] >= this_height do break
                    i += di
                    j += dj
                }
                else do break
            }
            this_scenic_score *= this_d_score
        }
        if this_scenic_score > max_scenic_score do max_scenic_score, max_i, max_j = this_scenic_score, i, j
    }
    {
        max_height := grid[max_i][max_j]
        for d in Directions
        {
            di, dj: int
            switch d
            {
                case .L: di, dj =  0, -1
                case .R: di, dj =  0,  1
                case .U: di, dj = -1,  0
                case .D: di, dj =  1,  0
            }
            i, j := max_i+di, max_j+dj
            for
            {
                if i >= 0 && i < GRID_SIDE && j >= 0 && j < GRID_SIDE
                {
                    visible[i][j] |= 0b10
                    if grid[i][j] >= max_height do break
                    i += di
                    j += dj
                }
                else do break
            }
        }
    }

    fmt.println(seen, max_scenic_score)

    rl.InitWindow(1900, 1000, "AoC 22.08")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    camera := rl.Camera3D{
        position = rl.Vector3{50, 50, 50},
        target = rl.Vector3{0, 0, 0},
        up = rl.Vector3{0, 1, 0},
        fovy = 45,
        projection = .PERSPECTIVE,
    }

    p1image := rl.GenImageColor(GRID_SIDE, GRID_SIDE, rl.BLACK)
    p2image := rl.GenImageColor(GRID_SIDE, GRID_SIDE, rl.BLACK)
    for i in 0..<GRID_SIDE do for j in 0..<GRID_SIDE {
        height := 255 % 9 + (255 / 9) * (grid[i][j] - '0') // 3-255
        invisible_color := rl.Color{height, 51, 51, 255}
        visible_color := rl.Color{51, height, 51, 255}
        rl.ImageDrawPixel(&p1image, i32(j), i32(i), bool(visible[i][j] & 0b01) ? visible_color : invisible_color)
        rl.ImageDrawPixel(&p2image, i32(j), i32(i), bool(visible[i][j] & 0b10) ? visible_color : invisible_color)
    }

    p1texture := rl.LoadTextureFromImage(p1image)
    defer rl.UnloadTexture(p1texture)
    p2texture := rl.LoadTextureFromImage(p2image)
    defer rl.UnloadTexture(p2texture)
    p1mesh := rl.GenMeshHeightmap(p1image, rl.Vector3{GRID_SIDE, 30, GRID_SIDE})
    p2mesh := rl.GenMeshHeightmap(p2image, rl.Vector3{GRID_SIDE, 30, GRID_SIDE})
    p1model := rl.LoadModelFromMesh(p1mesh)
    defer rl.UnloadModel(p1model)
    p2model := rl.LoadModelFromMesh(p2mesh)
    defer rl.UnloadModel(p2model)
    p1model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = p1texture
    p2model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = p2texture
    rl.UnloadImage(p1image)
    rl.UnloadImage(p2image)
    map_position := rl.Vector3{-GRID_SIDE / 2, 0, -GRID_SIDE / 2}
    view_mode := ViewMode.P1

    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.SPACE) do view_mode = view_mode == ViewMode.P1 ? ViewMode.P2 : ViewMode.P1
        rl.UpdateCamera(&camera, .ORBITAL)

        rl.BeginDrawing()
        defer rl.EndDrawing()
            rl.ClearBackground(rl.RAYWHITE)
            rl.BeginMode3D(camera)
                rl.DrawModel(view_mode == ViewMode.P1 ? p1model : p2model, map_position, 1.0, rl.WHITE)
            rl.EndMode3D()
            rl.DrawText("Press SPACE to toggle view", 10, 10, 20, rl.DARKGRAY)
    }
}