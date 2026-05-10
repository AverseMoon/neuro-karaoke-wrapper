# homebrew-neurokaraoke

Homebrew tap for [Neuro Karaoke Player](https://neurokaraoke.com).

## Install

```bash
brew install --cask aferilvt/neurokaraoke/neurokaraoke
```

Or shorter:

```bash
brew tap aferilvt/neurokaraoke
brew install --cask neurokaraoke
```

On Homebrew 4.0+ the `--cask` flag is optional if no formula collision exists:

```bash
brew install neurokaraoke
```

## Auto-update

The cask declares `auto_updates true` — the app updates itself via electron-updater. Homebrew won't reinstall on each release.

## Maintainer notes

This repo is the public tap. Source repo is [`aferilvt/neuro-karaoke-wrapper`](https://github.com/aferilvt/neuro-karaoke-wrapper).

When a new release is cut, the source repo dispatches `new-release` to this repo and `bump-cask.yml` updates `Casks/neurokaraoke.rb` automatically.

To trigger manually: Actions → "Bump cask on new release" → Run workflow → enter version.
