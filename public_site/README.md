# Lotus ERP public information pages

This directory contains a static application homepage and the Google backup
privacy policy required for the public OAuth application. It is separate from
the Flutter build and the existing digital customer-profile site.

Published pages:

- Homepage: https://lotus-erp-production.web.app/
- Privacy Policy: https://lotus-erp-production.web.app/privacy.html

Hosting is configured on the no-cost Spark plan with Analytics disabled.

Only `site/` is public. It contains no application credentials, account tokens,
databases, customer records, analytics or sign-in scripts. Review the support
contact and privacy text before publication.

Keep `site/google98a6b6d3fa0088ca.html` when updating or redeploying. This public
Search Console verification marker maintains the owner's website verification;
it is not an OAuth credential. Removing it can invalidate domain ownership.

## Local preview

From this directory:

```powershell
node preview.mjs
```

Open `http://127.0.0.1:8788/` and `http://127.0.0.1:8788/privacy.html`.
An optional port can be passed as the first argument. The preview server binds
only to loopback and serves the same response headers configured for Hosting.

## Hosting

`firebase.json` serves only `site/` and sets response headers for static content.
Firebase Hosting supports a no-cost Spark plan and default HTTPS subdomains;
check current quotas before deployment. Do not activate billing or upgrade to
Blaze as part of this static-site setup.

After the owner approves the content, hosting terms and publication, deploy with
the Firebase CLI authenticated as the project owner:

```powershell
npx --yes firebase-tools@15.37.0 deploy --only hosting --project lotus-erp-production --config firebase.json
```

Do not deploy the repository root, upload the Google client configuration, or
reuse the existing customer-profile site's hosting configuration.

After publication, verify the live homepage and privacy-policy links, configure
Google Auth Platform branding and domain ownership as required, complete the
applicable verification, and confirm the actual OAuth publishing status before
distributing Google Drive backup to public customers. A project name containing
"Production" does not change the application's publishing status.

See `../docs/GOOGLE_DRIVE_RELEASE_STATUS.md` for the recorded Google publishing,
ownership and branding status and the next required check.
