const std = @import("std");
const folder_mgmt = @import("folder_mgmt.zig");
const Database = @import("Database.zig");
const State = @import("state.zig");
const i18n = @import("i18n.zig");

/// CLI commands for folder management
pub const Command = enum {
    create,
    mount,
    unmount,
    list,
    delete,
    help,
};

pub fn parseCommand(cmd: []const u8) ?Command {
    if (std.mem.eql(u8, cmd, "create")) return .create;
    if (std.mem.eql(u8, cmd, "mount")) return .mount;
    if (std.mem.eql(u8, cmd, "unmount")) return .unmount;
    if (std.mem.eql(u8, cmd, "list")) return .list;
    if (std.mem.eql(u8, cmd, "delete")) return .delete;
    if (std.mem.eql(u8, cmd, "help")) return .help;
    return null;
}

pub fn showHelp() void {
    const help_text =
        \\PassKeeZ Folder Management
        \\
        \\Usage: passkeez-folders <command> [options]
        \\
        \\Commands:
        \\  create <name> <encrypted_path> <mount_point>
        \\      Create a new encrypted folder
        \\      Example: passkeez-folders create "My Docs" ~/.passkeez/docs ~/Documents/Secure
        \\
        \\  mount <folder_id>
        \\      Mount an encrypted folder
        \\      Example: passkeez-folders mount abc123...
        \\
        \\  unmount <folder_id>
        \\      Unmount an encrypted folder
        \\      Example: passkeez-folders unmount abc123...
        \\
        \\  list
        \\      List all encrypted folders
        \\      Example: passkeez-folders list
        \\
        \\  delete <folder_id>
        \\      Delete an encrypted folder configuration (does not delete encrypted data)
        \\      Example: passkeez-folders delete abc123...
        \\
        \\  help
        \\      Show this help message
        \\
        \\Requirements:
        \\  - gocryptfs must be installed
        \\  - User must have FUSE permissions
        \\
    ;
    std.debug.print("{s}\n", .{help_text});
}

pub fn createFolderDialog(allocator: std.mem.Allocator) !folder_mgmt.EncryptedFolder {
    // Get folder name
    const name_result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zigenity",
            "--entry",
            "--window-icon=/usr/share/passkeez/passkeez.png",
            "--title=Create Encrypted Folder",
            "--text=Enter a name for the encrypted folder:",
            "--entry-text=My Secure Folder",
        },
    }) catch |e| {
        std.log.err("Failed to get folder name: {any}", .{e});
        return error.DialogFailed;
    };
    defer {
        allocator.free(name_result.stdout);
        allocator.free(name_result.stderr);
    }

    if (name_result.term.Exited != 0) {
        return error.Cancelled;
    }

    const name = std.mem.trim(u8, name_result.stdout, &std.ascii.whitespace);
    if (name.len == 0) {
        return error.InvalidInput;
    }

    // Get encrypted storage path
    const enc_path_result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zigenity",
            "--file-selection",
            "--directory",
            "--window-icon=/usr/share/passkeez/passkeez.png",
            "--title=Select Encrypted Storage Location",
            "--text=Choose where to store encrypted data:",
        },
    }) catch |e| {
        std.log.err("Failed to get encrypted path: {any}", .{e});
        return error.DialogFailed;
    };
    defer {
        allocator.free(enc_path_result.stdout);
        allocator.free(enc_path_result.stderr);
    }

    if (enc_path_result.term.Exited != 0) {
        return error.Cancelled;
    }

    const encrypted_path = std.mem.trim(u8, enc_path_result.stdout, &std.ascii.whitespace);

    // Get mount point
    const mount_result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zigenity",
            "--file-selection",
            "--directory",
            "--window-icon=/usr/share/passkeez/passkeez.png",
            "--title=Select Mount Point",
            "--text=Choose where to mount the decrypted folder:",
        },
    }) catch |e| {
        std.log.err("Failed to get mount point: {any}", .{e});
        return error.DialogFailed;
    };
    defer {
        allocator.free(mount_result.stdout);
        allocator.free(mount_result.stderr);
    }

    if (mount_result.term.Exited != 0) {
        return error.Cancelled;
    }

    const mount_point = std.mem.trim(u8, mount_result.stdout, &std.ascii.whitespace);

    // Create the folder
    var manager = folder_mgmt.FolderManager.init(allocator);
    defer manager.deinit();

    const folder = try manager.createFolder(name, encrypted_path, mount_point);

    // Show success message
    _ = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zigenity",
            "--info",
            "--window-icon=/usr/share/passkeez/passkeez.png",
            "--icon=/usr/share/passkeez/passkeez-ok.png",
            "--title=Folder Created",
            "--text=Encrypted folder created successfully!",
            "--timeout=5",
        },
    }) catch {};

    return folder;
}

pub fn listFoldersDialog(allocator: std.mem.Allocator, db: *Database) !void {
    const folders = try db.listFolders(db, allocator);
    defer {
        for (folders) |*folder| {
            folder.deinit(allocator);
        }
        allocator.free(folders);
    }

    if (folders.len == 0) {
        _ = std.process.Child.run(.{
            .allocator = allocator,
            .argv = &.{
                "zigenity",
                "--info",
                "--window-icon=/usr/share/passkeez/passkeez.png",
                "--title=Encrypted Folders",
                "--text=No encrypted folders configured.",
                "--timeout=5",
            },
        }) catch {};
        return;
    }

    // Build list text
    var list_text = std.ArrayList(u8).init(allocator);
    defer list_text.deinit();

    const writer = list_text.writer();
    try writer.writeAll("Encrypted Folders:\n\n");

    for (folders) |folder| {
        try writer.print("Name: {s}\n", .{folder.name});
        try writer.print("ID: {s}\n", .{std.fmt.fmtSliceHexLower(&folder.id[0..8])});
        try writer.print("Mount Point: {s}\n", .{folder.mount_point});
        try writer.print("Status: {s}\n\n", .{if (folder.is_mounted) "Mounted" else "Unmounted"});
    }

    _ = std.process.Child.run(.{
        .allocator = allocator,
        .argv = &.{
            "zigenity",
            "--text-info",
            "--window-icon=/usr/share/passkeez/passkeez.png",
            "--title=Encrypted Folders",
            "--width=600",
            "--height=400",
        },
    }) catch {};
}

pub fn mountFolderDialog(allocator: std.mem.Allocator, db: *Database) !void {
    const folders = try db.listFolders(db, allocator);
    defer {
        for (folders) |*folder| {
            folder.deinit(allocator);
        }
        allocator.free(folders);
    }

    if (folders.len == 0) {
        _ = std.process.Child.run(.{
            .allocator = allocator,
            .argv = &.{
                "zigenity",
                "--error",
                "--window-icon=/usr/share/passkeez/passkeez.png",
                "--title=No Folders",
                "--text=No encrypted folders configured.",
            },
        }) catch {};
        return;
    }

    // Build selection list
    var list_items = std.ArrayList([]const u8).init(allocator);
    defer list_items.deinit();

    try list_items.append("zigenity");
    try list_items.append("--list");
    try list_items.append("--window-icon=/usr/share/passkeez/passkeez.png");
    try list_items.append("--title=Mount Folder");
    try list_items.append("--text=Select folder to mount:");
    try list_items.append("--column=Name");
    try list_items.append("--column=Mount Point");
    try list_items.append("--column=ID");

    for (folders) |folder| {
        try list_items.append(folder.name);
        try list_items.append(folder.mount_point);
        const id_str = try std.fmt.allocPrint(allocator, "{s}", .{std.fmt.fmtSliceHexLower(&folder.id[0..8])});
        try list_items.append(id_str);
    }

    const result = std.process.Child.run(.{
        .allocator = allocator,
        .argv = list_items.items,
    }) catch |e| {
        std.log.err("Failed to show folder selection: {any}", .{e});
        return error.DialogFailed;
    };
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }

    if (result.term.Exited != 0) {
        return error.Cancelled;
    }

    // Parse selection and mount
    const selected = std.mem.trim(u8, result.stdout, &std.ascii.whitespace);
    
    for (folders) |folder| {
        if (std.mem.eql(u8, folder.name, selected)) {
            var manager = folder_mgmt.FolderManager.init(allocator);
            defer manager.deinit();
            
            try manager.mountFolder(folder.id);
            
            _ = std.process.Child.run(.{
                .allocator = allocator,
                .argv = &.{
                    "zigenity",
                    "--info",
                    "--window-icon=/usr/share/passkeez/passkeez.png",
                    "--icon=/usr/share/passkeez/passkeez-ok.png",
                    "--title=Folder Mounted",
                    "--text=Encrypted folder mounted successfully!",
                    "--timeout=3",
                },
            }) catch {};
            
            return;
        }
    }
}
