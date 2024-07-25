// TODO: Dynamically change game result font size

const TileState = enum { x, o };
const WinState = struct {
    tiles: [3]usize,
    winner: TileState,
    condition: enum {
        horizontal,
        vertical,
        diagonal,
    },
};

const screen_width = 800;
const screen_height = 800;
const margin = 6;
const border_width = 4;

const player_x_color = rl.Color.red;
const player_o_color = rl.Color.dark_green;

pub fn main() !void {
    rl.initWindow(screen_width, screen_height, "TicTacToe");
    defer rl.closeWindow();

    var state: [9]?TileState = .{null} ** 9;
    var player: TileState = .x;
    var moves_played: usize = 0;
    var winner: ?WinState = null;
    rl.setTargetFPS(60);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.light_gray);
        // border
        rl.drawRectangle(0, 0, margin, screen_height, rl.Color.dark_brown);
        rl.drawRectangle(0, 0, screen_width, margin, rl.Color.dark_brown);
        rl.drawRectangle(screen_width - margin, 0, margin, screen_height, rl.Color.dark_brown);
        rl.drawRectangle(0, screen_height - margin, screen_width, margin, rl.Color.dark_brown);
        // tile separators
        rl.drawRectangle(screen_width / 3 - border_width / 2, 0, border_width, screen_height, rl.Color.dark_brown);
        rl.drawRectangle(2 * screen_width / 3 - border_width / 2, 0, border_width, screen_height, rl.Color.dark_brown);
        rl.drawRectangle(0, screen_height / 3 - border_width / 2, screen_width, border_width, rl.Color.dark_brown);
        rl.drawRectangle(0, 2 * screen_height / 3 - border_width / 2, screen_width, border_width, rl.Color.dark_brown);

        // user input
        if (rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left)) {
            if (userClick(&state, player)) |p| {
                player = p;
                moves_played += 1;
                if (checkWin(state)) |w| {
                    drawBoard(state);
                    winner = w;
                    break;
                }
            }
        }
        drawBoard(state);
        if (moves_played == 9) {
            break;
        }
    } else {
        // user exited from game
        return;
    }
    rl.beginDrawing();
    drawGameResult(winner);
    rl.endDrawing();
    // wait for user to close out of game
    while (!rl.windowShouldClose()) {
        rl.pollInputEvents();
    }
}

// TODO: include screen_width in font size calculation
fn drawGameResult(winner: ?WinState) void {
    const margin_inner = 10 * margin;
    const font = rl.getFontDefault();
    const font_size = margin_inner;
    const spacing = 4.0;
    const result_text: [:0]const u8 = if (winner) |w| switch (w.winner) {
        .x => "X wins!",
        .o => "The winner is O",
    } else "It's a tie!";
    var pos = rl.measureTextEx(font, result_text, font_size, spacing);
    pos.x = (screen_width - pos.x) / 2;
    pos.y = (screen_height - pos.y) / 2;

    rl.drawRectangle(
        margin_inner,
        margin_inner,
        screen_width - 2 * margin_inner,
        screen_height - 2 * margin_inner,
        rl.Color.init(128, 128, 128, 220),
    );
    rl.drawTextEx(font, result_text, pos, font_size, spacing, rl.Color.black);
}

fn threeEqual(a: anytype, b: @TypeOf(a), c: @TypeOf(a)) bool {
    return a == b and b == c;
}

fn checkWin(state: [9]?TileState) ?WinState {
    for (0..3) |i| {
        // check horizontal win
        if (state[i * 3] != null and
            threeEqual(state[i * 3], state[i * 3 + 1], state[i * 3 + 2]))
            return .{
                .winner = state[i * 3].?,
                .tiles = .{ i * 3, i * 3 + 1, i * 3 + 2 },
                .condition = .horizontal,
            };
        // check vertical win
        if (state[i] != null and
            threeEqual(state[i], state[i + 3], state[i + 6]))
            return .{
                .winner = state[i].?,
                .tiles = .{ i, i + 3, i + 6 },
                .condition = .vertical,
            };
    }
    // check diagonal win
    if (state[0] != null and threeEqual(state[0], state[4], state[8]))
        return .{
            .winner = state[0].?,
            .tiles = .{ 0, 4, 8 },
            .condition = .diagonal,
        };
    if (state[2] != null and threeEqual(state[2], state[4], state[6]))
        return .{
            .winner = state[2].?,
            .tiles = .{ 2, 4, 6 },
            .condition = .diagonal,
        };
    return null;
}

fn userClick(state: *[9]?TileState, player: TileState) ?TileState {
    const mouse_x = rl.getMouseX();
    const mouse_y = rl.getMouseY();

    const adjust = 2 * margin + 2 * border_width;
    const tile_width = (screen_width - adjust) / 3;
    const tile_height = (screen_height - adjust) / 3;

    const x_index: usize = switch (mouse_x) {
        margin...margin + tile_width => 0,
        margin + border_width + tile_width...margin + border_width + 2 * tile_width => 1,
        else => 2,
    };
    const y_index: usize = switch (mouse_y) {
        margin...margin + tile_height => 0,
        margin + border_width + tile_height...margin + border_width + 2 * tile_height => 1,
        else => 2,
    };

    if (state[x_index + y_index * 3] != null) {
        return null;
    }
    state[x_index + y_index * 3] = player;
    return switch (player) {
        .x => .o,
        .o => .x,
    };
}

fn drawBoard(state: [9]?TileState) void {
    const adjust = 2 * margin + 2 * border_width;
    const tile_width = (screen_width - adjust) / 3;
    const tile_height = (screen_height - adjust) / 3;
    for (state, 0..) |tile, i| {
        if (tile == null) {
            continue;
        }
        const j: i32 = @intCast(i);
        const centerX = margin + (tile_width + border_width) * @mod(j, 3) + tile_width / 2;
        const centerY = margin + (tile_height + border_width) * @divFloor(j, 3) + tile_height / 2;
        switch (tile.?) {
            .x => drawX(centerX, centerY, tile_width - 4 * border_width, tile_height - 4 * border_width),
            .o => drawO(centerX, centerY, tile_width - 4 * border_width, tile_height - 4 * border_width),
        }
    }
}

fn drawX(center_x: i32, center_y: i32, width: i32, height: i32) void {
    const hwidth = @divFloor(width, 2);
    const hheight = @divFloor(height, 2);
    rl.drawLineEx(
        .{ .x = @floatFromInt(center_x - hwidth), .y = @floatFromInt(center_y - hwidth) },
        .{ .x = @floatFromInt(center_x + hwidth), .y = @floatFromInt(center_y + hheight) },
        border_width,
        player_x_color,
    );
    rl.drawLineEx(
        .{ .x = @floatFromInt(center_x - hwidth), .y = @floatFromInt(center_y + hwidth) },
        .{ .x = @floatFromInt(center_x + hwidth), .y = @floatFromInt(center_y - hheight) },
        border_width,
        player_x_color,
    );
}

fn drawO(centerX: i32, centerY: i32, width: i32, height: i32) void {
    const hwidth = @divFloor(width, 2);
    const hheight = @divFloor(height, 2);
    for (0..border_width) |i| {
        const j: i32 = @intCast(i);
        rl.drawEllipseLines(centerX, centerY, @floatFromInt(hwidth + j), @floatFromInt(hheight + j), player_o_color);
    }
}

const std = @import("std");
const rl = @import("raylib");
