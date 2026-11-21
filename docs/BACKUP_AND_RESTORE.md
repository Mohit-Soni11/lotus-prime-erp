# Backup & Restore

Open **Settings → System → Backup & Restore**. The workspace opens above the
sidebar and returns to Settings with Back.

## Local backup

1. Select **Choose Folder**, or keep the default local destination.
2. Select **Back Up Now**.
3. Wait for the local copy to finish verification. A completed file has the
   `.lotusbackup` extension; incomplete work is never listed as a usable backup.

The package includes both business and owner/shop databases, business
preferences, customer and pledged-item photos, shop identity documents,
supplier attachments and issued invoice documents. Legacy attachments outside
managed directories are copied when their stored references can be resolved.
Files already missing are counted in the backup history and restore preview.
Database audit JSON is preserved; direct file references and preferences are
rebased to the destination installation during restore.

SQLite snapshots include committed WAL data. Brief write locks cover database
snapshot creation; compression and verification run outside the UI isolate.
Backup packages contain business data and are not password-encrypted archives.
Google authorization, active login sessions and the backup destination
configuration are not exported in the package.

## Automatic schedules

- **Manual only:** automatic backup is off.
- **Daily:** choose a local time.
- **Weekly:** choose weekday and local time.
- **Monthly:** choose day and local time. Day 29–31 falls on the month's final
  day when necessary.

Click **Save Schedule**. The scheduler checks on authorized application startup
and once a minute while the application is open. A missed period runs once on
the next authorized startup; it does not manufacture historical snapshots.
This release does not install a Windows background task and cannot run while
the computer or application is off.

The verified local copy is always created first. A failed Drive upload keeps
that file, shows a retry state, and retries while the application remains open
with Drive backup enabled. **Retry Upload** also retries the existing file
without taking another financial snapshot. Existing backups are not
automatically deleted.

## Google Drive: one-time setup

Account setup was deferred during implementation. No Google account has been
connected and no real business backup has been uploaded as part of development.

1. Sign in to [Google Cloud](https://console.cloud.google.com/).
2. Create/select the application project and enable **Google Drive API**.
3. Configure the Google Auth Platform branding and audience. For testing, add
   the intended Google account as a test user. Choose an appropriate personal
   or production audience for continued use when supported by your Google
   configuration; external testing-mode grants can expire after seven days.
4. Create an OAuth client with application type **Desktop app** and download
   its JSON configuration. A web client or service account cannot be used.
5. In Lotus ERP select **Set Up Google Drive → Import Desktop Client JSON**.
6. Select **Connect Google Account**. Use the external browser to sign in and
   approve the requested backup permission.
7. Keep **Include Google Drive** enabled to upload manual and scheduled backups.

The desktop flow uses loopback redirect, state validation and PKCE. Tokens and
client configuration use platform secure storage with separate development and
production keys. Nothing is embedded as a customer credential in source code.

Drive access is limited to `drive.appdata`, plus basic account identity. Files
are stored in the app's private `appDataFolder`, not the Gmail inbox or the
ordinary My Drive listing. The same Google application configuration should be
used on other installations that need to access the same backup area. The
application requests no Gmail-message or unrestricted Drive access.

Uploads use resumable chunks and verify the server's file size and MD5. Local
archives and downloaded packages additionally use SHA-256 file checks and
database integrity/schema verification before restore.

Official references:

- [Desktop OAuth](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Drive application data](https://developers.google.com/workspace/drive/api/guides/appdata)
- [Resumable uploads](https://developers.google.com/workspace/drive/api/guides/manage-uploads)
- [OAuth application states](https://developers.google.com/identity/protocols/oauth2/production-readiness/overview)

## Restore

1. Choose **Restore Local File**, or switch to **Google Drive**, refresh and
   select **Restore** on the required backup.
2. Review its creation time and verification result, including any unavailable
   media. Review the replacement warning before **Restore & Restart**.
3. The selected file is copied into a checked staging area. The application
   restarts and applies it before authentication or database startup.
4. Before replacement, a verified recovery backup of the current installation
   is created. File swaps are journaled. A failed or interrupted apply is rolled
   back before the application can use the databases.
5. Sign in with the local owner credentials from the restored backup.

Close other/older Lotus ERP instances before restore. Current-version processes
share an installation lease so a second copy cannot write through a restore.
Development builds prepare the restore but require stopping and relaunching
the development app; they do not spawn another `flutter_tester` or debug runner.

## Locations and recovery

Installed builds keep backup metadata and default local copies beneath:

`%LOCALAPPDATA%\Lotus ERP\Backups`

Development uses a separate `DevelopmentBackups` directory and its existing
development database locations. A backup/restore action in one environment does
not select the other environment's files.

- `Local/`: default completed local backups.
- `Recovery/`: verified snapshots taken immediately before a restore.
- `Work/`: temporary package creation/verification.
- `RestorePending/`: a staged restore and original preferences.
- `restore-journal.json`: durable apply/recovery state.
- `last-restore.json`: the most recent restore result.

Do not remove the journal or `.lotus-old-*` / `.lotus-new-*` resources while a
restore is being recovered. Restart the application to allow recovery to finish.
Archive validation rejects traversal, links, encrypted/unsupported ZIP methods,
duplicates, damaged payloads, excessive expansion and unsupported future schema
versions. Restore does not run schema migrations inside the import transaction;
normal application startup performs supported migrations afterwards.
