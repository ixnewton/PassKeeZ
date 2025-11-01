# Quick Start: Encrypted Folders in PassKeeZ

## 5-Minute Setup

### 1. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt install gocryptfs

# Arch Linux
sudo pacman -S gocryptfs

# Fedora
sudo dnf install gocryptfs
```

### 2. Verify Installation

```bash
which gocryptfs
# Should output: /usr/bin/gocryptfs
```

### 3. Create Your First Encrypted Folder

When PassKeeZ is unlocked, folders are automatically managed. Here's how to create one:

#### Option A: Via Code

```zig
const folder_mgmt = @import("folder_mgmt.zig");
const State = @import("state.zig");

// Create folder manager
var manager = folder_mgmt.FolderManager.init(allocator);
defer manager.deinit();

// Create encrypted folder
const folder = try manager.createFolder(
    "My Secure Documents",                    // Name
    "/home/user/.passkeez/encrypted/docs",   // Encrypted storage
    "/home/user/Documents/Secure"            // Mount point
);

// Save to database
try State.database.?.setFolder(&State.database.?, folder);

// Mount it
try manager.mountFolder(folder.id);
```

#### Option B: Via Dialog (When Implemented)

The dialog interface will guide you through:
1. Enter folder name
2. Choose encrypted storage location
3. Choose mount point
4. Done! Folder is created and mounted

### 4. Use Your Encrypted Folder

```bash
# Navigate to mount point
cd ~/Documents/Secure

# Create files (they're automatically encrypted)
echo "Secret data" > secret.txt

# Files are encrypted on disk
cat ~/.passkeez/encrypted/docs/secret.txt
# Output: Binary gibberish (encrypted)
```

### 5. Automatic Locking

PassKeeZ automatically:
- **Mounts** folders when you unlock the database
- **Unmounts** folders after 60 seconds of inactivity
- **Protects** your data when locked

## Common Use Cases

### Personal Documents

```zig
const folder = try manager.createFolder(
    "Personal Docs",
    "~/.passkeez/encrypted/personal",
    "~/Documents/Personal"
);
```

**Use for**: Tax documents, medical records, personal photos

### Work Files

```zig
const folder = try manager.createFolder(
    "Work Projects",
    "~/.passkeez/encrypted/work",
    "~/Work/Confidential"
);
```

**Use for**: Client data, proprietary code, business plans

### Password Manager Backups

```zig
const folder = try manager.createFolder(
    "Backups",
    "~/.passkeez/encrypted/backups",
    "~/Backups/Secure"
);
```

**Use for**: Database backups, recovery keys, encrypted archives

## Syncing Between Devices

### Setup Syncthing

```bash
# Install Syncthing
sudo apt install syncthing

# Start Syncthing
syncthing
```

### Configure Sync

1. **Sync the Database**:
   - Add `~/.config/passkeez/passkeys.kdbx` to Syncthing
   - This syncs folder configurations

2. **Sync Encrypted Data** (optional):
   - Add `~/.passkeez/encrypted/` to Syncthing
   - This syncs the actual encrypted files

3. **Don't Sync Mount Points**:
   - Mount points are device-specific
   - Each device can have different mount locations

## Troubleshooting

### "gocryptfs not found"

```bash
# Install it
sudo apt install gocryptfs

# Verify
which gocryptfs
```

### "Permission denied"

```bash
# Check FUSE permissions
groups $USER | grep fuse

# Add yourself to fuse group (if needed)
sudo usermod -a -G fuse $USER
# Then log out and back in
```

### "Mount point not empty"

```bash
# Unmount first
fusermount -u ~/Documents/Secure

# Or use a different mount point
```

### "Folder won't unmount"

```bash
# Check what's using it
lsof +D ~/Documents/Secure

# Force unmount
fusermount -uz ~/Documents/Secure
```

## Best Practices

### ✅ DO

- Use strong master password (20+ characters)
- Let PassKeeZ auto-lock after timeout
- Backup your KDBX database regularly
- Use descriptive folder names
- Keep encrypted storage in home directory

### ❌ DON'T

- Don't share master password
- Don't leave computer unlocked
- Don't store encrypted data on untrusted media
- Don't use weak passwords
- Don't manually edit KDBX database

## Security Tips

1. **Strong Password**: Use a passphrase like "correct-horse-battery-staple-2024"
2. **Encrypted Swap**: Enable to protect keys in memory
3. **Full Disk Encryption**: Use LUKS for additional security
4. **Regular Backups**: Backup KDBX database weekly
5. **Lock When Away**: Let timeout work, or lock manually

## Example Workflow

### Daily Use

```
Morning:
1. Unlock PassKeeZ (enter password)
2. Folders automatically mount
3. Work with files normally
4. Step away from computer
5. PassKeeZ auto-locks after 60s
6. Folders automatically unmount

Evening:
1. Unlock PassKeeZ again
2. Folders mount again
3. Continue working
4. Lock when done
```

### Syncing to Laptop

```
Desktop:
1. Create folder "Work Projects"
2. Add files to ~/Work/Confidential
3. Syncthing syncs KDBX + encrypted data

Laptop:
1. Syncthing receives KDBX + encrypted data
2. Unlock PassKeeZ
3. Folder auto-mounts to ~/Work/Confidential
4. Same files available!
```

## Command Reference

### Create Folder

```zig
const folder = try manager.createFolder(name, encrypted_path, mount_point);
try db.setFolder(&db, folder);
```

### Mount Folder

```zig
try manager.mountFolder(folder.id);
```

### Unmount Folder

```zig
try manager.unmountFolder(folder.id);
```

### List Folders

```zig
const folders = try db.listFolders(&db, allocator);
defer allocator.free(folders);

for (folders) |folder| {
    std.debug.print("{s}: {s}\n", .{folder.name, 
        if (folder.is_mounted) "Mounted" else "Unmounted"});
}
```

### Delete Folder

```zig
try manager.deleteFolder(folder.id);
try db.deleteFolder(&db, folder.id);
```

## Getting Help

- **Documentation**: See `FOLDER_MANAGEMENT.md` for details
- **Issues**: https://github.com/Zig-Sec/PassKeeZ/issues
- **Wiki**: https://github.com/Zig-Sec/PassKeeZ/wiki
- **Discussions**: https://github.com/Zig-Sec/PassKeeZ/discussions

## What's Next?

- Explore advanced features in `FOLDER_MANAGEMENT.md`
- Set up Syncthing for multi-device sync
- Configure backup strategy
- Integrate with your workflow

---

**Happy Encrypting! 🔒**
