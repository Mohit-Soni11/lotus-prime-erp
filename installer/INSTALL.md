# Lotus ERP for Windows

## Version 1 installation

Build the installer on a Windows development machine with Flutter, Visual
Studio C++ tooling, and Inno Setup 6:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\build_windows_installer.ps1
```

The installer is written to `dist/Lotus-ERP-Setup-1.0.0-x64.exe`. Copy that
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

For every update, close Lotus ERP and back up both
`%LOCALAPPDATA%\Lotus ERP\Data` and
`%APPDATA%\Lotus ERP\Lotus ERP` (preferences and the Windows protected
session), then increment
the `version` in `pubspec.yaml`, rebuild the installer, and run the new setup
on the same Windows user account. Run the new installer over the previous
installation; do not uninstall first. Database migrations run when the new
application starts. Keep the same `AppId` in `installer/lotus_erp.iss` and the
same production data path in `AppStoragePaths` for every release.

The protected session is tied to the Windows user. A data restore to another
computer may require signing in again with the local username and password.

Reinstalling Lotus ERP on a Windows profile that already contains production
data will reopen that data. Setup never deletes it. To start an unrelated new
shop on a different laptop, install under a Windows user profile with no
previous Lotus ERP production data.

The installer is currently unsigned. Windows may show a publisher warning
until a code-signing certificate is configured for release distribution.
