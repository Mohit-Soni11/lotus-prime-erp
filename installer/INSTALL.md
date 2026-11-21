# Lotus ERP for Windows

## Windows installer

Build the installer on a Windows development machine with Flutter, Visual
Studio C++ tooling, and Inno Setup 6:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\build_windows_installer.ps1
```

The installer is written to `dist/Lotus-ERP-Setup-<version>-x64.exe`. Copy that
single file to the target Windows laptop, run it, then launch Lotus ERP from
the Start menu. At first launch, create the local owner account, save the
one-time recovery code, and enter the shop profile and metal rates. No
internet connection or Firebase account is needed for sign-in.

The installer contains only the compiled application executable, DLLs, and
Flutter assets. It contains no shop profile, stock, rates, invoices, or
database files. A Windows user who has never run a production Lotus ERP build
starts with a fresh account and empty business records. Development records
are stored separately and are not imported into the installed application.

The old development shop database lived under `.dart_tool`, where
`flutter clean` could remove it. Development builds now keep that database
in their application-support directory. The installer build script cleans
only generated Release output.

## Data and updates

Production data, including both SQLite databases, issued invoices, photos,
and attachments, lives under `%LOCALAPPDATA%\Lotus ERP\Data`. The installer
is installed under `%LOCALAPPDATA%\Programs\Lotus ERP`. The installer also
bundles the required Visual C++ runtime DLLs. These locations are
stable across releases. Installing a later version with the same AppId
replaces application files and keeps the data directory. The owner's session
is restored after reopening the app until **Sign out** is selected. The
password itself is never stored as a session value.

For an update, close the application with its title-bar X; a business-day close
is not required. Run the new setup under the same Windows account. Setup detects
the previous installation, reuses its program folder, and offers **Update**.
Do not uninstall the previous version first.

Before replacing application files, Setup copies the complete Data directory
and `%APPDATA%\Lotus ERP\Lotus ERP` (preferences and protected session) into
`%LOCALAPPDATA%\Lotus ERP\Backups\before-<version>-<timestamp>`. Every copied
file is verified with SHA-256. A `backup-complete.txt` record identifies a
successfully verified backup. Backup failure or an open Lotus ERP window stops
the update before application files are replaced. Linked data folders require
a separate manual backup; Setup will not silently omit them.

Database migrations run when the updated app starts. Keep the same `AppId`
and production storage paths for every release. Increment `pubspec.yaml` and
the matching application metadata before building a new installer.

Release checks:

```powershell
flutter test tool/verify_installed_update_test.dart --dart-define=LOTUS_VERIFY_INSTALLED_COPY=true
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\tests\test_update_installer.ps1
```

The compatibility check opens installed databases read-only and upgrades only
consistent copies under the backup directory. It verifies database integrity
and preserves all existing row values. The installer test uses an isolated
product ID, synthetic records and separate data/settings directories.

The protected session is tied to the Windows user. A data restore to another
computer may require signing in again with the local username and password.

Reinstalling Lotus ERP on a Windows profile that already contains production
data will reopen that data. Setup never deletes it. To start an unrelated new
shop on a different laptop, install under a Windows user profile with no
previous Lotus ERP production data.

The installer is currently unsigned. Windows may show a publisher warning
until a code-signing certificate is configured for release distribution.
