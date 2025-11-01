# PassKeeZ Encrypted Folder Management

## Overview

PassKeeZ now supports managing encrypted folders alongside passkey authentication. This feature allows you to create, mount, and manage encrypted folders that are automatically unlocked when you authenticate with PassKeeZ.

## Features

- **Unified Authentication**: Single password unlocks both passkeys and encrypted folders
- **Automatic Mounting**: Folders are automatically mounted when you unlock PassKeeZ
- **Automatic Unmounting**: Folders are unmounted when PassKeeZ locks (after timeout)
- **Secure Storage**: Folder encryption keys stored in the same KDBX database as passkeys
- **Sync Support**: Folder configurations sync between devices via Syncthing
- **KeePassXC Compatible**: Folder entries visible in KeePassXC under "Encrypted Folders" group

## Requirements

### System Dependencies

1. **gocryptfs** - FUSE-based encrypted filesystem
   ```bash
   # Ubuntu/Debian
   sudo apt install gocryptfs
   
   # Arch Linux
   sudo pacman -S gocryptfs
   
   # Fedora
   sudo dnf install gocryptfs
   ```

2. **FUSE** - Filesystem in Userspace
   ```bash
   # Usually pre-installed, but if needed:
   sudo apt install fuse3
   ```

3. **User Permissions**
   - User must be in the `fuse` group (usually automatic)
   - Verify with: `groups $USER`

## Architecture

### Data Flow

```
┌─────────────────────────────────────────────────────────┐
│                    PassKeeZ Database                     │
│                      (KDBX Format)                       │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────┐      ┌─────────────────────────┐  │
│  │   Passkeys      │      │  Encrypted Folders      │  │
│  │   Group         │      │  Group                  │  │
│  ├─────────────────┤      ├─────────────────────────┤  │
│  │ • GitHub        │      │ • My Documents          │  │
│  │ • Google        │      │   - Encryption Key      │  │
│  │ • Twitter       │      │   - Mount Point         │  │
│  └─────────────────┘      │   - Encrypted Path      │  │
│                            │ • Work Files            │  │
│                            │ • Personal Data         │  │
│                            └─────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                              │
                              │ Unlock with password
                              ▼
┌─────────────────────────────────────────────────────────┐
│                   PassKeeZ Runtime                       │
├─────────────────────────────────────────────────────────┤
│  • FIDO2 Authenticator (for web login)                  │
│  • Folder Manager (auto-mount/unmount)                  │
└─────────────────────────────────────────────────────────┘
                              │
                              │ Mount folders
                              ▼
┌─────────────────────────────────────────────────────────┐
│                    Filesystem                            │
├─────────────────────────────────────────────────────────┤
│  ~/.passkeez/encrypted/docs  →  ~/Documents/Secure      │
│  ~/.passkeez/encrypted/work  →  ~/Work/Private          │
└─────────────────────────────────────────────────────────┘
```

### Storage Format

Folder entries are stored in the KDBX database as custom entries:

```
Entry Structure:
├── Title: "My Documents"
├── PassKeeZ.FolderID: "abc123..."
├── PassKeeZ.FolderData: <base64-encoded>
│   ├── ID (36 bytes)
│   ├── Name (variable)
│   ├── Encrypted Path (variable)
│   ├── Mount Point (variable)
│   ├── Encryption Key (32 bytes, AES-256)
│   ├── Salt (32 bytes)
│   ├── Created At (8 bytes)
│   └── Last Accessed (8 bytes)
└── Notes: "PassKeeZ Encrypted Folder"
```

## Usage

### Creating an Encrypted Folder

#### Via Dialog (Recommended)

When PassKeeZ is unlocked, you can create folders through the GUI dialogs:

1. The system will prompt for:
   - Folder name (e.g., "My Documents")
   - Encrypted storage location (e.g., `~/.passkeez/encrypted/docs`)
   - Mount point (e.g., `~/Documents/Secure`)

2. PassKeeZ will:
   - Generate a unique encryption key
   - Initialize the encrypted storage
   - Save configuration to database
   - Automatically mount the folder

#### Programmatically

```zig
const folder_mgmt = @import("folder_mgmt.zig");

var manager = folder_mgmt.FolderManager.init(allocator);
defer manager.deinit();

const folder = try manager.createFolder(
    "My Documents",
    "/home/user/.passkeez/encrypted/docs",
    "/home/user/Documents/Secure"
);

// Save to database
try State.database.?.setFolder(&State.database.?, folder);
```

### Mounting Folders

Folders are automatically mounted when you unlock PassKeeZ. Manual mounting:

```zig
try manager.mountFolder(folder.id);
```

The mount process:
1. Creates temporary key file
2. Calls `gocryptfs` with the key
3. Mounts encrypted storage to mount point
4. Removes temporary key file

### Unmounting Folders

Folders are automatically unmounted when PassKeeZ locks (after 60 seconds of inactivity). Manual unmounting:

```zig
try manager.unmountFolder(folder.id);
```

### Listing Folders

```zig
const folders = try State.database.?.listFolders(&State.database.?, allocator);
defer {
    for (folders) |*folder| {
        folder.deinit(allocator);
    }
    allocator.free(folders);
}

for (folders) |folder| {
    std.debug.print("Folder: {s}\n", .{folder.name});
    std.debug.print("Mounted: {}\n", .{folder.is_mounted});
}
```

### Deleting a Folder

```zig
try manager.deleteFolder(folder.id);
try State.database.?.deleteFolder(&State.database.?, folder.id);
```

**Note**: This only removes the configuration. Encrypted data remains on disk.

## Security Considerations

### Encryption

- **Algorithm**: AES-256-GCM (via gocryptfs)
- **Key Generation**: Cryptographically secure random (32 bytes)
- **Key Storage**: Encrypted in KDBX database (AES-256)
- **Salt**: Unique per folder (32 bytes)

### Key Management

1. **Master Password**: Protects KDBX database
2. **Database Encryption**: KDBX uses AES-256 to encrypt all entries
3. **Folder Keys**: Each folder has unique 256-bit encryption key
4. **No Key Reuse**: Each folder gets fresh cryptographic material

### Threat Model

**Protected Against:**
- Unauthorized access to encrypted storage (keys in database)
- Physical theft of storage device (data encrypted at rest)
- Network interception (no network transmission of keys)
- Offline attacks (KDBX uses key derivation with high iteration count)

**Not Protected Against:**
- Malware with root access (can read mounted filesystems)
- Keyloggers (can capture master password)
- Memory dumps while unlocked (keys in RAM)
- Coercion attacks (user forced to provide password)

### Best Practices

1. **Strong Master Password**: Use 20+ character passphrase
2. **Regular Backups**: Backup KDBX database regularly
3. **Lock When Idle**: Let PassKeeZ auto-lock after timeout
4. **Secure Mount Points**: Use mount points in user home directory
5. **Encrypted Swap**: Enable encrypted swap to protect keys in memory
6. **Full Disk Encryption**: Use LUKS/dm-crypt for additional layer

## Syncing Between Devices

### Using Syncthing

1. **Setup Syncthing** on all devices
2. **Sync KDBX Database**:
   ```bash
   # Add to Syncthing folders
   ~/.config/passkeez/passkeys.kdbx
   ```

3. **Sync Encrypted Storage** (optional):
   ```bash
   # Sync encrypted data between devices
   ~/.passkeez/encrypted/
   ```

4. **Mount Points**: Configure per-device (don't sync)

### Conflict Resolution

- KDBX format handles concurrent edits
- Syncthing creates conflict files if needed
- Resolve conflicts in KeePassXC by merging databases

## Troubleshooting

### Folder Won't Mount

**Error**: `gocryptfs mount failed`

**Solutions**:
1. Check gocryptfs is installed: `which gocryptfs`
2. Verify FUSE permissions: `groups $USER | grep fuse`
3. Check mount point exists and is empty
4. View logs: `journalctl -f | grep passkeez`

### Folder Won't Unmount

**Error**: `fusermount unmount failed`

**Solutions**:
1. Check if files are open: `lsof +D /mount/point`
2. Force unmount: `fusermount -uz /mount/point`
3. Kill processes using the mount

### Database Corruption

**Error**: `DatabaseError` when loading folders

**Solutions**:
1. Restore from backup
2. Open in KeePassXC and repair
3. Delete corrupted folder entries manually

### Permission Denied

**Error**: `PermissionDenied` when creating folders

**Solutions**:
1. Check directory permissions
2. Ensure user owns encrypted storage location
3. Verify mount point is writable

## Implementation Details

### Module Structure

```
src/
├── folder_mgmt.zig          # Core folder management logic
├── folder_cli.zig           # CLI interface and dialogs
├── database/
│   ├── FolderEntry.zig      # Folder entry serialization
│   └── kdbx.zig             # Database integration (extended)
├── Database.zig             # Database interface (extended)
├── state.zig                # State management (extended)
└── i18n.zig                 # Internationalization (extended)
```

### Key Functions

#### `FolderManager.createFolder()`
Creates new encrypted folder with unique key and initializes storage.

#### `FolderManager.mountFolder()`
Mounts encrypted folder using gocryptfs with temporary key file.

#### `FolderManager.unmountFolder()`
Unmounts folder using fusermount.

#### `Database.setFolder()`
Stores folder configuration in KDBX database under "Encrypted Folders" group.

#### `State.initFolderManager()`
Loads folders from database and auto-mounts on authentication.

## Future Enhancements

### Planned Features

1. **Multiple Encryption Backends**
   - CryFS support
   - eCryptfs support
   - Native Zig encryption

2. **Advanced Key Management**
   - Key rotation
   - Hardware key support (YubiKey)
   - Biometric unlock

3. **UI Improvements**
   - System tray integration
   - Desktop notifications
   - File manager integration

4. **Cloud Integration**
   - Direct cloud storage support
   - Encrypted cloud sync

5. **Mobile Support**
   - Android app
   - iOS app (if possible)

### Contributing

Contributions welcome! See main README.md for guidelines.

## License

Same as PassKeeZ main project (see LICENSE file).

## Support

- **Issues**: https://github.com/Zig-Sec/PassKeeZ/issues
- **Wiki**: https://github.com/Zig-Sec/PassKeeZ/wiki
- **Discussions**: https://github.com/Zig-Sec/PassKeeZ/discussions
