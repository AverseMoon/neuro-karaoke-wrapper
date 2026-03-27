# NeuroKaraoke iOS Port

This folder contains the SwiftUI iOS port of the Android `neuro-karaoke-wrapper` app.

## Current Status

The iOS app already includes:

- Home, Search, Explore, Library, Radio, Soundbites, Setlists, and Artists screens
- Song playback, mini player, full player, queue view, repeat/shuffle, and sleep timer
- Lyrics loading and synced lyric highlighting
- Favorites, downloads, and local user playlists
- Discord sign-in and library sync
- Background audio session and now-playing / remote command integration
- Explore/community playlists and About screen
- Audio Effects UI with persisted equalizer and bass boost state
- Hybrid playback backend:
  - Songs and soundbites use `AVAudioEngine`
  - Radio still uses `AVPlayer`

## Remaining Android Features To Migrate

### 1. Audio / Player Parity

- Apply equalizer and bass boost to live radio playback too
- Improve `AVAudioEngine` playback parity with the older `AVPlayer` path:
  - more robust seek/resume behavior
  - better interruption / route-change recovery
  - queue recovery after app/service-style restarts
- Match Android’s random-song fallback / auto-continue behavior when queues end
- Add richer queue editing:
  - reorder queue
  - remove queued items
  - clearer queue source handling

### 2. Update Flow

Android has update-check logic and update UI (`UpdateRepository`, `UpdateViewModel`, `UpdateDialog`).

Still missing on iOS:

- check for app updates
- present update information to the user
- open the correct download / store destination

### 3. Auth Parity

Current iOS auth uses Discord PKCE and deep-link callback handling.

Still missing vs Android:

- embedded WebView auth fallback
- JWT parsing / save flow from WebView login path
- setup-time login-page warmup/preload behavior

### 4. Setup Flow Parity

Current iOS startup is faster and background-loads the catalog, but it is still simpler than Android.

Still missing:

- Android-style multi-step setup UX
- more explicit setup diagnostics/progress stages
- login warmup integration during setup

### 5. Library / Download Parity

- bulk playlist download actions
- more Android-style download management polish
- stronger cache invalidation / staleness handling for downloaded and cached media

### 6. Data / Cache Parity

Android has more specialized cache handling through things like:

- `PlaylistCatalog`
- `SongCache`
- `LyricsCache`
- setlist staleness refresh logic

iOS still needs:

- fuller stale-cache detection
- more explicit catalog versioning / refresh strategy
- parity review for all cached playback/catalog/auth data

### 7. UI / UX Parity

Functionally the iOS port is much closer than before, but it is not a 1:1 Android UI port.

Still missing:

- Android drawer/top bar shell behavior
- more exact player screen composition and polish
- more exact screen-by-screen visual parity
- finer interaction polish across browse/search/library flows

## Recommended Next Migration Order

1. Finish player parity around the new `AVAudioEngine` path, especially radio + queue recovery
2. Add update-check flow
3. Add WebView auth fallback / setup parity
4. Add bulk playlist download actions
5. Do a final parity pass on cache behavior and UI polish
