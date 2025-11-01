const std = @import("std");
const keylib = @import("keylib");
const Database = @import("Database.zig");
const State = @import("state.zig");

/// Represents an encrypted folder configuration
pub const EncryptedFolder = struct {
    /// Unique identifier for the folder
    id: [36]u8,
    /// Display name for the folder
    name: []const u8,
    /// Path to the encrypted storage location
    encrypted_path: []const u8,
    /// Path where the folder should be mounted
    mount_point: []const u8,
    /// Encryption key (256-bit for AES-256)
    key: [32]u8,
    /// Salt for key derivation
    salt: [32]u8,
    /// Creation timestamp
    created_at: i64,
    /// Last accessed timestamp
    last_accessed: i64,
    /// Whether the folder is currently mounted
    is_mounted: bool,

    pub fn deinit(self: *EncryptedFolder, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.encrypted_path);
        allocator.free(self.mount_point);
        // Zero out sensitive data
        @memset(&self.key, 0);
        @memset(&self.salt, 0);
    }
};

/// Folder management errors
pub const Error = error{
    OutOfMemory,
    FolderNotFound,
    FolderAlreadyExists,
    MountFailed,
    UnmountFailed,
    EncryptionFailed,
    DecryptionFailed,
    InvalidPath,
    PermissionDenied,
    FolderInUse,
    InvalidKey,
};

/// Manages encrypted folders
pub const FolderManager = struct {
    allocator: std.mem.Allocator,
    folders: std.ArrayList(EncryptedFolder),
    
    pub fn init(allocator: std.mem.Allocator) FolderManager {
        return FolderManager{
            .allocator = allocator,
            .folders = std.ArrayList(EncryptedFolder).init(allocator),
        };
    }

    pub fn deinit(self: *FolderManager) void {
        for (self.folders.items) |*folder| {
            folder.deinit(self.allocator);
        }
        self.folders.deinit();
    }

    /// Create a new encrypted folder
    pub fn createFolder(
        self: *FolderManager,
        name: []const u8,
        encrypted_path: []const u8,
        mount_point: []const u8,
    ) Error!EncryptedFolder {
        // Generate unique ID
        var id: [36]u8 = undefined;
        const uuid = std.crypto.random.bytes(&id);
        _ = uuid;

        // Generate encryption key
        var key: [32]u8 = undefined;
        std.crypto.random.bytes(&key);

        // Generate salt
        var salt: [32]u8 = undefined;
        std.crypto.random.bytes(&salt);

        // Verify paths
        if (!std.fs.path.isAbsolute(encrypted_path)) {
            return Error.InvalidPath;
        }
        if (!std.fs.path.isAbsolute(mount_point)) {
            return Error.InvalidPath;
        }

        // Create encrypted storage directory
        std.fs.cwd().makePath(encrypted_path) catch |e| {
            std.log.err("Failed to create encrypted storage path: {any}", .{e});
            return Error.EncryptionFailed;
        };

        // Create mount point directory
        std.fs.cwd().makePath(mount_point) catch |e| {
            std.log.err("Failed to create mount point: {any}", .{e});
            return Error.MountFailed;
        };

        const folder = EncryptedFolder{
            .id = id,
            .name = try self.allocator.dupe(u8, name),
            .encrypted_path = try self.allocator.dupe(u8, encrypted_path),
            .mount_point = try self.allocator.dupe(u8, mount_point),
            .key = key,
            .salt = salt,
            .created_at = std.time.milliTimestamp(),
            .last_accessed = std.time.milliTimestamp(),
            .is_mounted = false,
        };

        try self.folders.append(folder);
        return folder;
    }

    /// Mount an encrypted folder using gocryptfs
    pub fn mountFolder(self: *FolderManager, folder_id: [36]u8) Error!void {
        const folder = self.findFolder(folder_id) orelse return Error.FolderNotFound;
        
        if (folder.is_mounted) {
            return; // Already mounted
        }

        // Create a temporary key file for gocryptfs
        const key_file_path = try std.fmt.allocPrint(
            self.allocator,
            "/tmp/passkeez_key_{s}",
            .{std.fmt.fmtSliceHexLower(&folder.id[0..8])},
        );
        defer self.allocator.free(key_file_path);

        // Write key to temporary file
        const key_file = std.fs.cwd().createFile(key_file_path, .{
            .mode = 0o600,
        }) catch |e| {
            std.log.err("Failed to create key file: {any}", .{e});
            return Error.MountFailed;
        };
        defer key_file.close();
        defer std.fs.cwd().deleteFile(key_file_path) catch {};

        key_file.writeAll(&folder.key) catch |e| {
            std.log.err("Failed to write key file: {any}", .{e});
            return Error.MountFailed;
        };

        // Mount using gocryptfs
        const result = std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &.{
                "gocryptfs",
                "-passfile",
                key_file_path,
                folder.encrypted_path,
                folder.mount_point,
            },
        }) catch |e| {
            std.log.err("Failed to execute gocryptfs: {any}", .{e});
            return Error.MountFailed;
        };
        defer {
            self.allocator.free(result.stdout);
            self.allocator.free(result.stderr);
        }

        if (result.term.Exited != 0) {
            std.log.err("gocryptfs mount failed: {s}", .{result.stderr});
            return Error.MountFailed;
        }

        folder.is_mounted = true;
        folder.last_accessed = std.time.milliTimestamp();
    }

    /// Unmount an encrypted folder
    pub fn unmountFolder(self: *FolderManager, folder_id: [36]u8) Error!void {
        const folder = self.findFolder(folder_id) orelse return Error.FolderNotFound;
        
        if (!folder.is_mounted) {
            return; // Already unmounted
        }

        // Unmount using fusermount
        const result = std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &.{
                "fusermount",
                "-u",
                folder.mount_point,
            },
        }) catch |e| {
            std.log.err("Failed to execute fusermount: {any}", .{e});
            return Error.UnmountFailed;
        };
        defer {
            self.allocator.free(result.stdout);
            self.allocator.free(result.stderr);
        }

        if (result.term.Exited != 0) {
            std.log.err("fusermount unmount failed: {s}", .{result.stderr});
            return Error.UnmountFailed;
        }

        folder.is_mounted = false;
    }

    /// Unmount all mounted folders
    pub fn unmountAll(self: *FolderManager) void {
        for (self.folders.items) |*folder| {
            if (folder.is_mounted) {
                self.unmountFolder(folder.id) catch |e| {
                    std.log.err("Failed to unmount folder {s}: {any}", .{ folder.name, e });
                };
            }
        }
    }

    /// Delete an encrypted folder
    pub fn deleteFolder(self: *FolderManager, folder_id: [36]u8) Error!void {
        const index = for (self.folders.items, 0..) |folder, i| {
            if (std.mem.eql(u8, &folder.id, &folder_id)) {
                break i;
            }
        } else return Error.FolderNotFound;

        var folder = self.folders.orderedRemove(index);
        
        // Ensure it's unmounted
        if (folder.is_mounted) {
            try self.unmountFolder(folder.id);
        }

        // Optionally delete encrypted data
        // std.fs.cwd().deleteTree(folder.encrypted_path) catch {};
        
        folder.deinit(self.allocator);
    }

    /// Find a folder by ID
    fn findFolder(self: *FolderManager, folder_id: [36]u8) ?*EncryptedFolder {
        for (self.folders.items) |*folder| {
            if (std.mem.eql(u8, &folder.id, &folder_id)) {
                return folder;
            }
        }
        return null;
    }

    /// List all folders
    pub fn listFolders(self: *FolderManager) []EncryptedFolder {
        return self.folders.items;
    }
};

/// Initialize folder management from database
pub fn loadFromDatabase(allocator: std.mem.Allocator, db: *Database) Error!FolderManager {
    var manager = FolderManager.init(allocator);
    
    // TODO: Load folder configurations from database
    // This will be implemented when database schema is extended
    
    return manager;
}

/// Save folder configurations to database
pub fn saveToDatabase(manager: *FolderManager, db: *Database) Error!void {
    // TODO: Save folder configurations to database
    // This will be implemented when database schema is extended
    _ = manager;
    _ = db;
}
