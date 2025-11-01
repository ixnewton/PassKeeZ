const std = @import("std");

pub const Text = struct {
    auth_select_title: []const u8 = "--title=PassKeeZ: Authenticator Selection",
    auth_select: []const u8 = "--text=Do you want to use PassKeeZ as your authenticator?",
    user_presence_title: []const u8 = "--title=PassKeeZ: Authentication Request",
    user_presence: []const u8 = "--text=Would you like to login to the following page?:",
    user_presence_fallback: []const u8 = "Unknown Website",
    unlock_database_title: []const u8 = "--title=PassKeeZ: Unlock Database",
    unlock_database: []const u8 = "--text=Please enter your password",
    unlock_database_ok: []const u8 = "--ok-label=Unlock",
    database_decryption_failed_title: []const u8 = "--title=PassKeeZ: Wrong Password",
    database_decryption_failed: []const u8 = "--text=Credential database decryption failed! Please verify that the password you've entered is correct.",
    too_many_attempts_title: []const u8 = "--title=PassKeeZ: Authentication failed",
    too_many_attempts: []const u8 = "--text=Too many incorrect password attempts",
    no_database_title: []const u8 = "--title=PassKeeZ: No Database",
    no_database: []const u8 = "--text=Do you want to create a new passkey database?",
    new_database_title: []const u8 = "--title=PassKeeZ: New Database",
    new_database: []const u8 = "--text=Please choose a password for your new database",
    new_database_ok: []const u8 = "--ok-label=Create",
    database_created_title: []const u8 = "--title=PassKeeZ: Success",
    database_created: []const u8 = "--text=Database successfully create",
    // Folder management strings
    folder_create_title: []const u8 = "--title=PassKeeZ: Create Encrypted Folder",
    folder_create_name: []const u8 = "--text=Enter a name for the encrypted folder:",
    folder_create_success: []const u8 = "--text=Encrypted folder created successfully!",
    folder_mount_title: []const u8 = "--title=PassKeeZ: Mount Folder",
    folder_mount_success: []const u8 = "--text=Folder mounted successfully!",
    folder_mount_failed: []const u8 = "--text=Failed to mount folder. Please check gocryptfs is installed.",
    folder_unmount_title: []const u8 = "--title=PassKeeZ: Unmount Folder",
    folder_unmount_success: []const u8 = "--text=Folder unmounted successfully!",
    folder_unmount_failed: []const u8 = "--text=Failed to unmount folder.",
    folder_delete_title: []const u8 = "--title=PassKeeZ: Delete Folder",
    folder_delete_confirm: []const u8 = "--text=Are you sure you want to delete this folder configuration?",
    folder_list_title: []const u8 = "--title=PassKeeZ: Encrypted Folders",
    folder_no_folders: []const u8 = "--text=No encrypted folders configured.",
};

const english: Text = .{};
const german: Text = .{
    .auth_select_title = "--title=PassKeeZ: Authentikator Auswählen",
    .auth_select = "--text=Möchten Sie PassKeeZ als Ihren Authentikator verwenden?",
    .user_presence_title = "--title=PassKeeZ: Login Bestätigen",
    .user_presence = "--text=Möchten Sie sich bei der folgenden Seite einloggen?:",
    .user_presence_fallback = "Unknown Website",
    .unlock_database_title = "--title=PassKeeZ: Passwort-Datenbank Entschlüsseln",
    .unlock_database = "--text=Bitte geben Sie Ihr Passwort ein um die Passwort-Datenbank zu entschlüsseln",
    .unlock_database_ok = "--ok-label=Entschlüsseln",
    .database_decryption_failed_title = "--title=PassKeeZ: Falsches Passwort",
    .database_decryption_failed = "--text=Die Entschlüsselung der Datenbank ist fehlgeschlagen! Bitte überprüfen Sie das eingegebene Passwort.",
    .too_many_attempts_title = "--title=PassKeeZ: Authentifizierung Fehlgeschlagen",
    .too_many_attempts = "--text=Zu viele inkorrekte Passworteingaben",
    .no_database_title = "--title=PassKeeZ: Keine Passwort-Datenbank Gefunden",
    .no_database = "--text=Möchten Sie eine neue Passwort-Datenbank anlegen?",
    .new_database_title = "--title=PassKeeZ: Passwort-Datenbank Anlegen",
    .new_database = "--text=Bitte legen Sie ein Passwort für Ihre Datenbank fest",
    .new_database_ok = "--ok-label=Anlegen",
    .database_created_title = "--title=PassKeeZ: Passwort-Datenbank Angelegt",
    .database_created = "--text=Passwort-Datenbank erfolgreich angelget",
    // Folder management strings (German)
    .folder_create_title = "--title=PassKeeZ: Verschlüsselten Ordner Erstellen",
    .folder_create_name = "--text=Geben Sie einen Namen für den verschlüsselten Ordner ein:",
    .folder_create_success = "--text=Verschlüsselter Ordner erfolgreich erstellt!",
    .folder_mount_title = "--title=PassKeeZ: Ordner Einhängen",
    .folder_mount_success = "--text=Ordner erfolgreich eingehängt!",
    .folder_mount_failed = "--text=Einhängen fehlgeschlagen. Bitte überprüfen Sie, ob gocryptfs installiert ist.",
    .folder_unmount_title = "--title=PassKeeZ: Ordner Aushängen",
    .folder_unmount_success = "--text=Ordner erfolgreich ausgehängt!",
    .folder_unmount_failed = "--text=Aushängen fehlgeschlagen.",
    .folder_delete_title = "--title=PassKeeZ: Ordner Löschen",
    .folder_delete_confirm = "--text=Sind Sie sicher, dass Sie diese Ordnerkonfiguration löschen möchten?",
    .folder_list_title = "--title=PassKeeZ: Verschlüsselte Ordner",
    .folder_no_folders = "--text=Keine verschlüsselten Ordner konfiguriert.",
};

pub fn get(lang: []const u8) *const Text {
    if (std.mem.eql(u8, lang, "english")) {
        return &english;
    } else if (std.mem.eql(u8, lang, "german")) {
        return &german;
    } else {
        return &english;
    }
}
