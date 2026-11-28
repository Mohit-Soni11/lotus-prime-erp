# Password recovery

Lotus ERP keeps the owner sign-in email and password locally. Existing username accounts remain supported. The **Forgot Password** button opens a four-screen flow inside the sign-in card: registered email, six-digit OTP, new password, and success. The left branding panel and background stay in place. The offline recovery code remains available from the first screen.

## Google account setup

1. After creating a company, save the offline recovery code. Lotus ERP then opens Google sign-in for the email entered in Create Company. Select that same account and grant the requested permissions. A different Google email is rejected and its connection removed.
2. If authorization is skipped or fails, sign in and open **Backup & Restore → Google Drive Backup → Connect Google Account**. Confirm the current Lotus ERP password and choose the company email. Its verified email and Google subject become the backup account and password recovery identity.
3. The connection requests Drive app-data and `gmail.send` permissions together. An account connected before the OTP update must be reconnected once to grant `gmail.send`. Keep the offline recovery code until that is done.
4. Enable the Gmail API in the Google Cloud project used by the desktop OAuth client. The OAuth consent configuration must allow the intended users and the sensitive `gmail.send` scope. Google may require OAuth verification before general distribution.

The OTP is sent **from the connected Google account to that same verified email**. Lotus ERP checks both the email and Google subject before sending. Codes are generated with a secure random source, expire after 10 minutes, allow five attempts, and are held only in app memory. Resending takes at least one minute and invalidates the previous code. Closing the app requires requesting a new code. A successful reset rotates the offline recovery code, which the owner must save from the success screen.

The login UI does not ask for or accept an email link. The older Firebase email-link implementation remains for previously enrolled accounts and the Security & Access enrollment flow; it is not used by this OTP screen. A Firebase-only recovery email without a linked Google account cannot receive this OTP. Use the saved offline recovery code or link the Google account while signed in.

## Build and delivery

The Google OAuth desktop client configuration is in `config/google-drive.local.json` outside Git. Build with the existing Google Drive define file. There is no separate paid OTP provider or embedded mail API key. Gmail access and email delivery depend on Google account authorization, the Gmail API, account sending limits, network availability, and Google's OAuth verification requirements. Test actual delivery from a connected account before relying on email recovery.

For a VS Code terminal debug run, use `flutter run -d windows --dart-define-from-file=config/google-drive.local.json --dart-define-from-file=config/email-recovery.json`, or select the **Lotus ERP - Windows** launch configuration. In debug mode, plain `flutter run -d windows` also reads the local Google client file from the project directory when present. Release builds still require an explicitly supplied Google client configuration. Debug and release installations keep separate account databases and secure Google tokens. Test the connection in the environment being used; the app reports an unlinked recovery email instead of claiming that an OTP was sent.

The local password reset never proceeds merely because a send request succeeded. The code must be verified against the active challenge, and the verified challenge is consumed on reset. Password reset is still available offline with the owner's recovery code.
