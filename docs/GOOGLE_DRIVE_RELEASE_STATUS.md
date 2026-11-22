# Google Drive release status

Recorded on 22 November 2026. This records the observed setup state; it is not a
claim that Google has approved branding or that every release check is complete.

## Completed

- Google Cloud project: `lotus-erp-production` (Lotus ERP Production).
- Desktop OAuth client: Lotus ERP Windows Desktop.
- Google Drive API: Enabled.
- Declared scopes: `drive.appdata`, `userinfo.email` and `openid`; no sensitive
  or restricted scopes. Google's Data access status says verification is not
  required for this scope set.
- OAuth audience: External. Publishing status: **In production**.
- Application identity is in the Git-ignored
  `config/google-drive.local.json`, supplied through Dart build configuration.
  No customer Google account or token is built into the application.
- VS Code profile: **Lotus ERP - Windows with Google Drive**.
- Windows debug build with this application identity: successful.
- Real account sign-in, account identification and private Drive backup listing:
  verified in the development application. This did not upload business records.
- Homepage: https://lotus-erp-production.web.app/
- Privacy Policy: https://lotus-erp-production.web.app/privacy.html
- Firebase Hosting: **Spark, No-cost ($0/month)**. Analytics was disabled and
  billing was not enabled during setup.
- Live pages and response headers: verified over HTTPS.
- Search Console ownership for `https://lotus-erp-production.web.app/`:
  **Ownership verified**, using the HTML-file method under the project owner.

## Google branding recheck

Google's first branding check reported that the homepage was not registered to
the owner. Search Console ownership has now been verified. The Google issues
panel explicitly says to wait 24 hours after verification before retrying so
its systems can update.

Ownership confirmation was recorded at **22 November 2026, 12:37:46 IST**
(`2026-11-22T07:07:46Z`). Retry **after 23 November 2026, 12:38 IST**. This is
the earliest recorded retry time, not a guarantee of approval at that time.

1. Keep `public_site/site/google98a6b6d3fa0088ca.html` published and reachable.
2. Open Google Auth Platform → Branding for `lotus-erp-production`.
3. Open Information and summary → View issues.
4. Select **I have fixed the issues**, then **Proceed** to request re-verification.
5. Observe the result. Record any further issue accurately; do not claim that
   branding is approved while the verification status says otherwise.

The application is in production, but Google currently reports that its branding
is not being shown to users until branding verification succeeds. Customer
authorization still requires each customer to approve their own account access.
Testing-mode user allowlists are no longer the onboarding mechanism.

## Remaining release checks

- Complete the branding recheck after Google's required wait.
- Verify the public account-selection experience with an account that was not
  on the development test-user list, using the intended release build.
- Perform an explicitly authorized backup upload/download and restore rehearsal
  on disposable data before claiming a live end-to-end recovery test. No real
  business backup upload or restore was performed during this setup.
- Package the next intended desktop update with the same application identity.
  No new installer was produced during this setup; the verified build was the
  development build. Existing installed copies need a build containing this
  configuration and feature code.

Application credentials remain private developer configuration. Account tokens
remain in device secure storage and are not included in the public website,
source-control changes or business backup packages.
