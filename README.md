# Tetris (Zig + Raylib)

A small Tetris clone written in Zig with raylib for rendering. It uses a 7-bag generator, SRS-style kicks, a preview queue, score/level tracking, and a glowy UI theme.

## Requirements
- Zig 0.15.2 or newer (per `build.zig.zon`)
- Dependencies fetched via Zig's package manager (handled by `build.zig.zon`)

## Build & Run
```bash
zig build --fetch      # grab raylib-zig dependency the first time
zig build run          # debug build
zig build -Drelease-safe run   # optimized run
```

## Controls
- Arrow Left/Right or A/D: move
- Arrow Up/W/X: rotate clockwise
- Z/Q: rotate counter-clockwise
- Arrow Down/S: soft drop
- Space: hard drop
- P: pause
- R: restart after game over

## Formatting
```bash
zig fmt src
```

## License
MIT. See `LICENSE`.
