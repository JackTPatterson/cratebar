# Releasing Cratebar

Releases are automated by [`.github/workflows/release.yml`](.github/workflows/release.yml).

## Cut a release

```bash
# bump nothing by hand — just tag and push
git tag v1.1
git push origin v1.1
```

On a `v*` tag push, the workflow (macOS runner) will:

1. Build `Cratebar.app` via `Scripts/build-app.sh`
2. Zip it to `Cratebar-<version>.zip` and compute its `sha256`
3. Create a GitHub Release with the zip attached + install notes
4. **Auto-bump the cask** in `JackTPatterson/homebrew-tap` (version + sha256),
   _if_ the `HOMEBREW_TAP_TOKEN` secret is set (see below)

The version is derived from the tag (`v1.1` → `1.1`), which must match the
zip name and the cask's `url`/`version`.

## One-time setup: tap auto-bump token

The cask lives in a **separate** repo, so the workflow needs a token with
write access to it. Without the secret, the release still publishes — only
step 4 is skipped (the run logs the version + sha256 to bump manually).

1. Create a **fine-grained PAT**: GitHub → Settings → Developer settings →
   Fine-grained tokens → *Generate new token*.
   - **Repository access:** only `JackTPatterson/homebrew-tap`
   - **Permissions:** Contents → **Read and write**
2. Add it to the source repo:
   ```bash
   gh secret set HOMEBREW_TAP_TOKEN --repo JackTPatterson/cratebar
   # paste the token when prompted
   ```

That's it — future `git push origin vX.Y` releases are fully hands-off.

## Notarization (optional, removes the Gatekeeper warning)

The shipped app is **ad-hoc signed**, so users must right-click → Open (or strip
quarantine) on first launch. To remove that friction you need an Apple Developer
Program membership and a Developer ID certificate — see the "Notarization"
section in the release workflow comments / project notes for the CI wiring.
