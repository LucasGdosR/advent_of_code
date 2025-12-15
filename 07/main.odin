package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

Directory :: struct {
    size: int,
    name: string, // For visualization purposes only
    parent: ^Directory,
    subdirectories: map[string]^Directory,
}

main :: proc()
{
    input, ok := os.read_entire_file("input")
    if !ok do os.exit(1)

    root : Directory = {name="/"}
    root.parent = &root
    curr := &root

    // First pass:
    // Build the directory tree and add files to their size
    it := string(input)
    for line in strings.split_lines_iterator(&it)
    {
        switch line[0] {
            // Command
            case '$':
                if line[2] == 'c' // cd
                {
                    switch line[5] {
                        case '.': curr = curr.parent // ..
                        case '/': curr = &root
                        case: curr = curr.subdirectories[line[5:]] // cd `dirname`
                    }
                }
                // else ls, do nothing
            // Directory
            case 'd':
                subdir := line[4:]
                new_dir := new(Directory)
                new_dir.parent = curr
                new_dir.name = subdir
                curr.subdirectories[subdir] = new_dir
            // File
            case:
                size: int
                for i := 0; line[i] != ' '; i += 1 do size = size * 10 + int(line[i] - '0')
                curr.size += size
        }
    }
    // Second pass:
    // DFS to add the size of subdirectories recursively
    // Note which subdirectories are smaller than 100000
    // Keep track of all directory sizes
    directory_sizes := make([dynamic]int)
    p1 := dfs(&root, 0, &directory_sizes)
    target_space_to_delete := 30_000_000 - (70_000_000 - root.size)
    min := 30_000_000
    for size in directory_sizes do if size >= target_space_to_delete && size < min do min = size

    // Visualize solution
    print_directories_recursively(&root, min, 0)
    fmt.println("\nPart 1:", p1, "\nPart2:", min)
}

dfs :: proc(curr: ^Directory, p1_acc: int, directory_sizes: ^[dynamic]int) -> int
{
    acc := p1_acc
    for _, dirstruct in curr.subdirectories
    {
        acc = dfs(dirstruct, acc, directory_sizes)
        curr.size += dirstruct.size
    }
    append(directory_sizes, curr.size)
    return curr.size <= 100_000 ? curr.size + acc : acc
}

print_directories_recursively :: proc(dir: ^Directory, deleted_dir, depth: int)
{
    line_builder := strings.builder_make_len_cap(0, 37 + depth * 4, context.temp_allocator)
    for i := 0; i < depth - 1; i += 1 do strings.write_string(&line_builder, "│   ")
    if depth > 0 do strings.write_string(&line_builder, "├── ")
    if dir.size <= 100_000 do strings.write_string(&line_builder, fmt.tprintf("📁 %s [%d]", dir.name, dir.size))
    else if dir.size == deleted_dir do strings.write_string(&line_builder, fmt.tprintf("📁 %s %d 🗑️ DELETED", dir.name, dir.size))
    else do strings.write_string(&line_builder, fmt.tprintf("📁 %s %d", dir.name, dir.size))
    fmt.println(strings.to_string(line_builder))
    free_all(context.temp_allocator)
    for _, subdir in dir.subdirectories do print_directories_recursively(subdir, deleted_dir, depth + 1)
}
