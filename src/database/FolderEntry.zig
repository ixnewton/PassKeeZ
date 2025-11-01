const std = @import("std");

/// Represents a folder entry stored in the KDBX database
/// This structure is serialized and stored as a custom entry type
pub const FolderEntry = struct {
    /// Unique identifier (UUID format)
    id: [36]u8,
    
    /// Display name for the folder
    name: []const u8,
    
    /// Path to encrypted storage
    encrypted_path: []const u8,
    
    /// Mount point path
    mount_point: []const u8,
    
    /// Encryption key (stored encrypted in KDBX)
    key: [32]u8,
    
    /// Salt for key derivation
    salt: [32]u8,
    
    /// Creation timestamp
    created_at: i64,
    
    /// Last accessed timestamp
    last_accessed: i64,
    
    /// Metadata for KDBX entry
    pub const ENTRY_TYPE = "PassKeeZ.EncryptedFolder";
    pub const ENTRY_ICON = 48; // Folder icon in KeePass
    
    pub fn init(
        allocator: std.mem.Allocator,
        name: []const u8,
        encrypted_path: []const u8,
        mount_point: []const u8,
    ) !FolderEntry {
        var id: [36]u8 = undefined;
        std.crypto.random.bytes(&id);
        
        var key: [32]u8 = undefined;
        std.crypto.random.bytes(&key);
        
        var salt: [32]u8 = undefined;
        std.crypto.random.bytes(&salt);
        
        return FolderEntry{
            .id = id,
            .name = try allocator.dupe(u8, name),
            .encrypted_path = try allocator.dupe(u8, encrypted_path),
            .mount_point = try allocator.dupe(u8, mount_point),
            .key = key,
            .salt = salt,
            .created_at = std.time.milliTimestamp(),
            .last_accessed = std.time.milliTimestamp(),
        };
    }
    
    pub fn deinit(self: *FolderEntry, allocator: std.mem.Allocator) void {
        allocator.free(self.name);
        allocator.free(self.encrypted_path);
        allocator.free(self.mount_point);
        @memset(&self.key, 0);
        @memset(&self.salt, 0);
    }
    
    /// Serialize to KDBX entry format
    pub fn toKdbxEntry(self: *const FolderEntry, allocator: std.mem.Allocator) ![]u8 {
        var buffer = std.ArrayList(u8).init(allocator);
        errdefer buffer.deinit();
        
        const writer = buffer.writer();
        
        // Write version
        try writer.writeInt(u32, 1, .little);
        
        // Write ID
        try writer.writeAll(&self.id);
        
        // Write name length and data
        try writer.writeInt(u32, @intCast(self.name.len), .little);
        try writer.writeAll(self.name);
        
        // Write encrypted_path length and data
        try writer.writeInt(u32, @intCast(self.encrypted_path.len), .little);
        try writer.writeAll(self.encrypted_path);
        
        // Write mount_point length and data
        try writer.writeInt(u32, @intCast(self.mount_point.len), .little);
        try writer.writeAll(self.mount_point);
        
        // Write key
        try writer.writeAll(&self.key);
        
        // Write salt
        try writer.writeAll(&self.salt);
        
        // Write timestamps
        try writer.writeInt(i64, self.created_at, .little);
        try writer.writeInt(i64, self.last_accessed, .little);
        
        return buffer.toOwnedSlice();
    }
    
    /// Deserialize from KDBX entry format
    pub fn fromKdbxEntry(allocator: std.mem.Allocator, data: []const u8) !FolderEntry {
        var stream = std.io.fixedBufferStream(data);
        const reader = stream.reader();
        
        // Read version
        const version = try reader.readInt(u32, .little);
        if (version != 1) return error.UnsupportedVersion;
        
        // Read ID
        var id: [36]u8 = undefined;
        try reader.readNoEof(&id);
        
        // Read name
        const name_len = try reader.readInt(u32, .little);
        const name = try allocator.alloc(u8, name_len);
        errdefer allocator.free(name);
        try reader.readNoEof(name);
        
        // Read encrypted_path
        const encrypted_path_len = try reader.readInt(u32, .little);
        const encrypted_path = try allocator.alloc(u8, encrypted_path_len);
        errdefer allocator.free(encrypted_path);
        try reader.readNoEof(encrypted_path);
        
        // Read mount_point
        const mount_point_len = try reader.readInt(u32, .little);
        const mount_point = try allocator.alloc(u8, mount_point_len);
        errdefer allocator.free(mount_point);
        try reader.readNoEof(mount_point);
        
        // Read key
        var key: [32]u8 = undefined;
        try reader.readNoEof(&key);
        
        // Read salt
        var salt: [32]u8 = undefined;
        try reader.readNoEof(&salt);
        
        // Read timestamps
        const created_at = try reader.readInt(i64, .little);
        const last_accessed = try reader.readInt(i64, .little);
        
        return FolderEntry{
            .id = id,
            .name = name,
            .encrypted_path = encrypted_path,
            .mount_point = mount_point,
            .key = key,
            .salt = salt,
            .created_at = created_at,
            .last_accessed = last_accessed,
        };
    }
};
