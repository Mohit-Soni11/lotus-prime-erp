# Email password recovery

Lotus ERP keeps its local username, Argon2id password, and offline recovery code. Firebase Authentication is used only to send a one-time email link and verify mailbox ownership. The local password is changed only when Firebase returns the same email and user ID that were verified for this installation.

## Owner setup

1. Sign in and open **Backup & Restore → Google Drive Backup → Connect Google Account**.
2. Confirm the current Lotus ERP password, then select the Google account. Its verified email becomes the backup account and recovery email in one connection.
3. If Google Drive was already connected before this feature was installed, select **Use for password recovery** in the same panel and confirm the Lotus password. The existing Google connection is reused.
4. When needed, use **Forgot password → Email link** on the login screen. Copy the complete link address from the email into Lotus ERP, set a new password, and save the newly issued offline recovery code.

**Security & Access → Recovery Email** remains an alternative when Google Drive is not configured. It requires a separate email verification link. A business email typed during company setup is not automatically trusted for password recovery because ownership has not been verified.

Email recovery works only after this one-time link. Existing owner accounts remain valid and can still use their recovery code. Email recovery needs internet access. A restored backup retains the verified email, Google account ID, and Firebase user ID (once a recovery link has been used); it must be restored into a build configured for the same Firebase project.

## Build configuration

The Firebase web app's public API key and HTTPS continuation URL are in `config/email-recovery.json`. Build with:

```powershell
flutter build windows --release --dart-define-from-file=config/google-drive.local.json --dart-define-from-file=config/email-recovery.json
```

VS Code's **Lotus ERP - Windows** launch configuration supplies both files. The Google Drive configuration is kept outside Git. Builds without Firebase defines keep local login and recovery-code reset, but email recovery is unavailable. Builds without the Google Drive configuration can still use the alternative verification in Security & Access.

The Firebase project is on the free Spark plan. Email-link sign-in currently has a limit of five emails per day on Spark, so the offline recovery code remains important. The project must have Email/Password and Email Link sign-in enabled and the continuation domain listed under authorized domains.
