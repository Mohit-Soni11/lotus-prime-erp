# Backup & Restore

Open **Settings → System → Backup & Restore**. The workspace opens above the
sidebar and returns to Settings with Back.

## Local backup

1. Select **Choose Folder**, or keep the default local destination.
2. Select **Back Up Now**.
3. Wait for the local copy to finish verification. A completed file has the
   `.lotusbackup` extension; incomplete work is never listed as a usable backup.

The Google Drive card has an **Also save to Google Drive** switch. With it off,
**Back Up Now** creates a local backup only. With it on, the same action first
creates and verifies a local backup, then uploads that package to the connected
Google account. The status card shows the destination for the next backup.
The switch also applies to scheduled backups; selecting **Google Drive** in
**Backups & Recovery** changes which history is displayed, not the destination.

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

## Connect a Google account

The developer's Google application identity is configured in the local build
settings. Initial account sign-in, account identification and the private Drive
backup listing have been verified in the development build. A live business
backup upload and restore have not been performed during this setup.

1. Select **Connect Google Account**. Use the external browser to sign in and
   approve the requested backup permission.
2. Return to Lotus ERP. The connected account appears in the Google Drive card.
3. Turn on **Also save to Google Drive** when you want manual and scheduled
   backups uploaded to that account. Turn it off for local-only backups.

There is no Google Cloud or JSON-import setup in the customer workspace. A build
with the developer's application identity retains that identity in device secure
storage so subsequent application starts can reuse it. Missing build settings do
not delete a saved Google connection. If neither build settings nor a saved
application identity are available, Google connection is unavailable while local
backup and restore continue to work.

The desktop flow uses loopback redirect, state validation and PKCE. Account
tokens use platform secure storage with separate development and production
keys. Existing connections from the earlier configuration flow are retained
when the application client ID matches. A different application ID requires
connecting again and cannot reuse the previous application's account tokens.

### Developer configuration before release

This is a one-time application setup, not a task for each customer:

1. Create/select the Lotus ERP project in [Google Cloud](https://console.cloud.google.com/)
   and enable **Google Drive API**.
2. Configure branding, audience and consent. During testing, add the intended
   test accounts. Complete the applicable production publishing requirements
   before distribution; external testing-mode grants can expire after seven days.
3. Create an OAuth client of type **Desktop app**. Web and service-account
   credentials are not supported by this desktop flow.
4. Copy `config/google-drive.example.json` to `config/google-drive.local.json`.
   Fill `LOTUS_GOOGLE_CLIENT_ID` and `LOTUS_GOOGLE_CLIENT_SECRET` with the
   Desktop application's values. This is a Dart build-configuration file,
   not Google's downloaded `installed` JSON. The local file is ignored by Git.
   Never put a user's email, password, account tokens or business data in it.
5. For development run:

   ```powershell
   flutter run -d windows --dart-define-from-file=config/google-drive.local.json
   ```

   In VS Code, select **Lotus ERP - Windows with Google Drive** in Run and Debug,
   then start debugging. This profile passes the local build configuration
   automatically. Stop and relaunch after changing application client values;
   hot reload cannot change compile-time configuration. The workspace has one
   Windows run profile, which includes Google configuration.
6. `installer/build_windows_installer.ps1` automatically includes that local
   configuration when it exists. Alternatively supply `-GoogleDriveConfig`
   with the path to a build-configuration JSON. Missing configuration, invalid
   keys or invalid values stop packaging before the build. An intentional build
   without Google configuration requires `-AllowLocalBackupOnly`. No JSON
   configuration file is copied beside
   the installed application; the application identity is compiled into it.

Desktop application identity is not an individual customer's login or backup
data. Desktop client values are extractable from a distributed native binary;
they must not be treated as confidential server credentials. Google grants
access only after each user signs in and approves the requested permissions.
Use the same application identity for updates and other installations that
need access to the same private backup area.

Before distributing to public customers, complete the production audience and
branding requirements, including the application's public homepage and privacy
policy. A Google project named "Production" is not proof that OAuth publishing
is in production: verify the actual publishing status in Google Auth Platform.
Testing-mode allowlists are for development and must not become a customer
onboarding requirement.

The public homepage and backup privacy-policy source is in `public_site/`.
The reviewed pages are published at `https://lotus-erp-production.web.app/`
and `https://lotus-erp-production.web.app/privacy.html` on Firebase Hosting's
no-cost Spark plan. Analytics is disabled. These source files are not bundled
with the desktop installer.

The Google OAuth audience is External and its publishing status has been
confirmed as In production. Google reports that data-access verification is
not required for the configured non-sensitive scopes. App branding has its
own verification status and must be checked separately before claiming that
Google has approved the displayed application identity.

Website ownership has been verified in Search Console. Google's branding check
requires waiting 24 hours after ownership verification before retrying. The
recorded retry time and remaining checks are in `GOOGLE_DRIVE_RELEASE_STATUS.md`.

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
