# Tap setup (one-time)

## 1. Create the tap repo

GitHub repo MUST be named `homebrew-neurokaraoke` (Homebrew convention).

```bash
gh repo create aferilvt/homebrew-neurokaraoke --public \
  --description "Homebrew tap for Neuro Karaoke Player"
```

## 2. Push these files

From inside the existing `homebrew/` folder of `neuro-karaoke`:

```bash
cd homebrew
git init
git remote add origin git@github.com:aferilvt/homebrew-neurokaraoke.git
git add .
git commit -m "initial cask"
git branch -M main
git push -u origin main
```

## 3. Compute initial SHAs

The cask currently has placeholder `REPLACE_WITH_*_SHA256` values. Either:

a) **Trigger the bump workflow manually** once after first push:
   - Actions tab → "Bump cask on new release" → Run workflow → version `1.5.2`

b) **Or compute locally and edit:**
   ```bash
   curl -L -o arm.dmg "https://github.com/aferilvt/neuro-karaoke-wrapper/releases/download/v1.5.2/Neuro%20Karaoke%20Player-1.5.2-arm64.dmg"
   curl -L -o x64.dmg "https://github.com/aferilvt/neuro-karaoke-wrapper/releases/download/v1.5.2/Neuro%20Karaoke%20Player-1.5.2-x64.dmg"
   shasum -a 256 arm.dmg x64.dmg
   ```
   Paste both SHAs into `Casks/neurokaraoke.rb`, commit, push.

## 4. Wire up auto-bump (optional but recommended)

In the source repo (`neuro-karaoke-wrapper`), add a step to your release workflow that dispatches to this tap:

```yaml
- name: Notify Homebrew tap
  run: |
    curl -X POST \
      -H "Authorization: token ${{ secrets.HOMEBREW_TAP_PAT }}" \
      -H "Accept: application/vnd.github.v3+json" \
      https://api.github.com/repos/aferilvt/homebrew-neurokaraoke/dispatches \
      -d '{"event_type":"new-release","client_payload":{"version":"${{ steps.version.outputs.value }}"}}'
```

`HOMEBREW_TAP_PAT` is a fine-grained PAT with **Contents: Read+Write** on the `homebrew-neurokaraoke` repo.

## 5. Test

```bash
brew tap aferilvt/neurokaraoke
brew install --cask neurokaraoke
```

If install succeeds, app launches from /Applications, you're done.

## Troubleshooting

- **`Cask not found`**: tap repo must be exactly `homebrew-neurokaraoke` (lowercase, with `homebrew-` prefix).
- **`SHA256 mismatch`**: cask SHA stale — re-run bump workflow.
- **`brew install neurokaraoke` (no --cask) fails**: requires Homebrew ≥ 4.0; tell user to use `brew install --cask aferilvt/neurokaraoke/neurokaraoke`.
