# README Addition for Encrypted Folder Feature

## Suggested Addition to Main README.md

Add this section after the "Features" section:

---

## Encrypted Folder Management (New in v0.6.0)

PassKeeZ now supports managing encrypted folders alongside passkey authentication!

### What is it?

Create encrypted folders that automatically mount when you unlock PassKeeZ and unmount when it locks. Perfect for securing sensitive documents, work files, or personal data.

### Key Features

* **Unified Authentication** - Single password unlocks both passkeys and encrypted folders
* **Automatic Mounting** - Folders mount when you authenticate, unmount on timeout
* **AES-256 Encryption** - Military-grade encryption via gocryptfs
* **Sync Support** - Folder configurations sync between devices via Syncthing
* **KeePassXC Compatible** - View and manage folders in KeePassXC

### Quick Start

```bash
# Install gocryptfs
sudo apt install gocryptfs  # Ubuntu/Debian
sudo pacman -S gocryptfs    # Arch Linux

# Create an encrypted folder (via code)
const folder = try manager.createFolder(
    "My Documents",
    "~/.passkeez/encrypted/docs",
    "~/Documents/Secure"
);

# That's it! Folder is created, encrypted, and mounted
```

### Documentation

* **Quick Start**: See [QUICK_START_FOLDERS.md](QUICK_START_FOLDERS.md)
* **Full Guide**: See [FOLDER_MANAGEMENT.md](FOLDER_MANAGEMENT.md)
* **Implementation**: See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)

### Security

* AES-256-GCM encryption per file
* Unique encryption key per folder
* Keys stored encrypted in KDBX database
* Automatic unmounting on timeout
* Compatible with full disk encryption

### Use Cases

* **Personal Documents** - Tax records, medical files, personal photos
* **Work Files** - Client data, proprietary code, business plans
* **Backups** - Encrypted backups of important data
* **Sensitive Data** - Anything requiring encryption at rest

### Requirements

* Linux (FUSE support required)
* gocryptfs 2.0+
* FUSE 3.0+

---

## Alternative: Shorter Version

If you prefer a more concise addition:

---

## 🔒 New: Encrypted Folder Management

PassKeeZ now manages encrypted folders alongside passkeys! Create folders that automatically mount when you unlock PassKeeZ.

**Features**: AES-256 encryption • Auto-mount/unmount • Syncthing support • KeePassXC compatible

**Quick Start**: `sudo apt install gocryptfs` → Create folder → Done!

**Docs**: [Quick Start](QUICK_START_FOLDERS.md) | [Full Guide](FOLDER_MANAGEMENT.md)

---

## Suggested Update to Features Section

Replace the existing "Features" section with:

---

## Features

### Passkey Authentication
* Works with all services that support Passkeys
* Store your Passkeys (private key + related data) in a local, encrypted database
* Constant sign-counter for safe credential syncing between devices
* Compatible with all major browsers (Chrome, Firefox, Brave, Opera)

### Encrypted Folder Management (New!)
* Create encrypted folders with AES-256 encryption
* Automatic mounting when database unlocks
* Automatic unmounting on timeout (60 seconds)
* Folder encryption keys stored in KDBX database
* Sync folder configurations between devices
* KeePassXC compatible for easy management

### Database & Sync
* KDBX format (compatible with KeePass and KeePassXC)
* Manage passkeys and folders using KeePassXC
* Sync databases between devices using Syncthing
* Regular backups recommended

---

## Suggested Addition to Getting Started Section

Add after the "Database Management" subsection:

---

### Encrypted Folders (Optional)

PassKeeZ can manage encrypted folders for your sensitive files:

1. **Install gocryptfs**:
   ```bash
   sudo apt install gocryptfs  # Ubuntu/Debian
   sudo pacman -S gocryptfs    # Arch Linux
   sudo dnf install gocryptfs  # Fedora
   ```

2. **Create folders**: Folders are created and managed programmatically or via dialogs

3. **Use normally**: Access files in mount points like regular folders

4. **Automatic security**: Folders unmount when PassKeeZ locks

See [QUICK_START_FOLDERS.md](QUICK_START_FOLDERS.md) for detailed instructions.

---

## Suggested Addition to QA Section

Add a new question:

---

<details>
<summary><ins>What are encrypted folders and why would I use them?</ins></summary>

Encrypted folders are a new feature in PassKeeZ v0.6.0 that allows you to create and manage encrypted storage alongside your passkeys. When you unlock PassKeeZ with your password, both your passkeys and encrypted folders become available. When PassKeeZ locks (after 60 seconds of inactivity), the folders are automatically unmounted and secured.

**Use cases:**
- **Personal documents**: Tax records, medical files, personal photos
- **Work files**: Client data, proprietary code, confidential documents
- **Backups**: Encrypted backups of important data
- **Sensitive data**: Anything requiring encryption at rest

**Benefits:**
- Single password for everything (passkeys + folders)
- Automatic mounting/unmounting (no manual commands)
- Military-grade AES-256 encryption
- Sync between devices (via Syncthing)
- Compatible with KeePassXC

**How it works:**
PassKeeZ uses gocryptfs (a FUSE-based encrypted filesystem) to create encrypted storage. The encryption keys are stored in your KDBX database, so the same password that unlocks your passkeys also unlocks your folders. This provides a seamless, secure experience.

See [FOLDER_MANAGEMENT.md](FOLDER_MANAGEMENT.md) for complete documentation.

</details>

---

## Complete Example README Section

Here's a complete section you could add:

---

## 🔒 Encrypted Folder Management

### Overview

PassKeeZ v0.6.0 introduces encrypted folder management, allowing you to secure sensitive files alongside your passkeys. Folders automatically mount when you unlock PassKeeZ and unmount when it locks.

### Features

| Feature | Description |
|---------|-------------|
| **Unified Auth** | Same password unlocks passkeys and folders |
| **Auto-Mount** | Folders mount automatically on unlock |
| **Auto-Unmount** | Folders unmount after 60s timeout |
| **AES-256** | Military-grade encryption via gocryptfs |
| **Sync Support** | Configurations sync via Syncthing |
| **KeePassXC** | Manage folders in KeePassXC |

### Quick Example

```zig
// Create encrypted folder
const folder = try manager.createFolder(
    "My Documents",                          // Name
    "/home/user/.passkeez/encrypted/docs",  // Encrypted storage
    "/home/user/Documents/Secure"           // Mount point
);

// Save to database
try database.setFolder(&database, folder);

// Mount it (or let PassKeeZ auto-mount)
try manager.mountFolder(folder.id);

// Use it!
// Files in ~/Documents/Secure are automatically encrypted
```

### Installation

```bash
# Install gocryptfs
sudo apt install gocryptfs  # Ubuntu/Debian
sudo pacman -S gocryptfs    # Arch Linux
sudo dnf install gocryptfs  # Fedora

# Verify installation
which gocryptfs
```

### Documentation

* 📖 **[Quick Start Guide](QUICK_START_FOLDERS.md)** - Get started in 5 minutes
* 📚 **[Full Documentation](FOLDER_MANAGEMENT.md)** - Complete guide with examples
* 🔧 **[Implementation Details](IMPLEMENTATION_SUMMARY.md)** - Technical documentation
* 📝 **[Changelog](CHANGES.md)** - What's new in v0.6.0

### Security

Encrypted folders use a multi-layer security approach:

```
User Data (files)
    ↓
gocryptfs (AES-256-GCM per-file)
    ↓
Folder Keys (32-byte AES keys)
    ↓
KDBX Database (AES-256 + Argon2)
    ↓
Master Password
```

**Result**: Your files are protected by both gocryptfs encryption AND KDBX database encryption.

### Use Cases

#### Personal Documents
```zig
const personal = try manager.createFolder(
    "Personal",
    "~/.passkeez/encrypted/personal",
    "~/Documents/Personal"
);
```
Store: Tax records, medical files, personal photos

#### Work Files
```zig
const work = try manager.createFolder(
    "Work",
    "~/.passkeez/encrypted/work",
    "~/Work/Confidential"
);
```
Store: Client data, proprietary code, business plans

#### Backups
```zig
const backups = try manager.createFolder(
    "Backups",
    "~/.passkeez/encrypted/backups",
    "~/Backups/Secure"
);
```
Store: Database backups, recovery keys, encrypted archives

### Syncing Between Devices

1. **Setup Syncthing** on all devices
2. **Sync KDBX database**: `~/.config/passkeez/passkeys.kdbx`
3. **Sync encrypted data** (optional): `~/.passkeez/encrypted/`
4. **Unlock on any device**: Folders available everywhere!

### FAQ

**Q: Do I need to use encrypted folders?**  
A: No, it's completely optional. PassKeeZ works as before for passkeys only.

**Q: Can I use KeePassXC to manage folders?**  
A: Yes! Folders appear in the "Encrypted Folders" group in KeePassXC.

**Q: What happens if I forget to unmount?**  
A: PassKeeZ automatically unmounts after 60 seconds of inactivity.

**Q: Can I sync folders between devices?**  
A: Yes, using Syncthing to sync both the database and encrypted data.

**Q: Is this secure?**  
A: Yes, uses AES-256 encryption with keys stored in encrypted KDBX database.

### Requirements

* Linux (FUSE support)
* gocryptfs 2.0+
* FUSE 3.0+
* PassKeeZ v0.6.0+

### Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | ✅ Supported | Full support via FUSE |
| Windows | ❌ Not yet | Planned (via Dokan/WinFsp) |
| macOS | ❌ Not yet | Planned (via OSXFUSE) |

---

This provides comprehensive information while remaining accessible to users!
