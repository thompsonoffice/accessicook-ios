# CI workflows

`ios-ci.yml` (simulator build, unit tests, UI tests, and accessibility audits) and `testflight-upload.yml` (signing and upload, disabled until App Store Connect secrets exist) live in `.github/workflows/`.

That is the same setup as [atguide-ios](https://github.com/thompsonoffice/atguide-ios), where the files are staged under `ci/workflows/` until a login with GitHub's `workflow` permission moves them. Here they are already in the directory GitHub Actions runs.

`ios-ci.yml` runs on every pull request and on every push to `main`. It does not sign or upload. `testflight-upload.yml` is manual only, and its job stays skipped until the repository variable `ENABLE_TESTFLIGHT_UPLOAD` is `true` and the secrets in `docs/APP-STORE-SETUP.md` exist.
