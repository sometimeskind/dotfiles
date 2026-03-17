# Music Library Pipeline

A self-hosted music pipeline: Spotify playlists → local M4A files → beets-managed library → Navidrome.

## Packages

Three dotfiles packages work together:

| Package | Stow target | Purpose |
|---------|-------------|---------|
| `beets` | `~/.config/beets/config.yaml` | Library management, tag fixing |
| `spotdl` | `~/.spotdl/config.json` | Download quality settings |
| `music` | `~/.local/bin/music-{setup,ingest,import}` | Pipeline scripts |

---

## Dependencies

```bash
pip install beets spotdl
```

Optional — for reviewing quarantined files:

```bash
sudo apt install picard   # or download from https://picard.musicbrainz.org
```

Verify both tools are on your `PATH`:

```bash
beet version
spotdl --version
```

Make sure `~/.local/bin` is on your `PATH`. If not, add to your shell config:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## First-time setup

### 1. Stow the packages

```bash
cd ~/src/dotfiles
make stow PKG=beets
make stow PKG=spotdl
make stow PKG=music
```

Ensure the scripts are executable:

```bash
chmod +x ~/.local/bin/music-setup ~/.local/bin/music-ingest ~/.local/bin/music-import
```

### 2. Set up Spotify developer credentials (required)

The scripts use your own Spotify app credentials to avoid hitting rate limits on spotdl's shared public client ID.

1. Go to [developer.spotify.com/dashboard](https://developer.spotify.com/dashboard) and create an app
2. Set the redirect URI to `http://127.0.0.1:8888/callback`
3. Copy the **Client ID** and **Client Secret**
4. Save them in 1Password as a new item:
   - Vault: `Private`
   - Item name: `Spotify Developer App`
   - Fields: `client_id`, `client_secret`

The scripts read these at runtime via `op read` — nothing is stored on disk.

### 3. Set up YouTube Premium cookies (required)

spotdl requires YouTube Premium cookies to download at full quality (M4A 256 kbps). Without them, the scripts will not run.

1. Install the **"Get cookies.txt LOCALLY"** browser extension (Chrome or Firefox)
2. Go to `https://music.youtube.com` while logged in to your YouTube Premium account
3. Export cookies in **Netscape format**
4. Save the file to `~/.config/spotdl/cookies.txt`

> **Note:** Cookies expire over time. If downloads start failing, re-export and overwrite `~/.config/spotdl/cookies.txt`.

The cookies file is not committed to the dotfiles repo (it is personal and rotates).

### 4. Add a playlist

```bash
music-setup
```

You will be prompted for:
- A playlist **name** (slug, e.g. `liked-songs`, `workout`)
- The **Spotify URL** for that playlist (Spotify → playlist → Share → Copy Link)

This creates:

```
~/Music/inbox/spotdl/
  liked-songs.spotdl     ← spotdl sync state; do not delete
  liked-songs/           ← spotdl downloads land here
~/Music/library/         ← beets-managed, tagged files
~/Music/quarantine/      ← low-confidence imports awaiting manual review
~/Music/playlists/       ← generated .m3u files
```

Run `music-setup` once per playlist. Each invocation adds one playlist without touching existing ones.

---

## Ongoing use

### Sync all playlists

```bash
music-ingest
```

For **each** `.spotdl` file found in `~/Music/inbox/spotdl/`, runs the full pipeline:

1. `spotdl sync` — downloads any new tracks into `~/Music/inbox/spotdl/<name>/`
2. `beet import --set source=<name>` — queries MusicBrainz, auto-accepts high-confidence matches, **moves** files into `~/Music/library/` (one copy on disk)
3. Generates `~/Music/playlists/<name>.m3u` with relative paths (required for Navidrome)
4. Quarantine sweep — audio files left in the download dir (beets skipped them) are moved to `~/Music/quarantine/`

After all playlists are processed:

5. `music-import` — imports anything manually dropped into `~/Music/inbox/`
6. `beet update` — refreshes library metadata and detects moved files

> **Note:** `beet update` does not remove entries for deleted files. To prune the library manually after deleting files from disk, run `beet remove <query>` with a specific query (e.g. `beet remove artist:OldArtist`). Avoid running `beet remove` with no query — it matches all items.

### Manual file adds

Drop any audio file into `~/Music/inbox/`, then run `music-import` (or `music-ingest` for a full sync). The file will be imported, tagged, and moved to `~/Music/library/`. It will not appear in any playlist.

```bash
music-import
```

---

## Quarantine workflow

Low-confidence MusicBrainz matches are moved to `~/Music/quarantine/` rather than being silently imported with bad tags.

To process them:

1. Open `~/Music/quarantine/` in **MusicBrainz Picard**
2. Look up and fix tags manually
3. Save the files to `~/Music/inbox/` (not back to quarantine)
4. Run `music-import` — beets will re-attempt import with the corrected tags

---

## How beets works

### Match threshold

`config.yaml` sets `strong_rec_thresh: 0.05`. Beets uses a **distance** score internally where 0 = perfect match and higher = worse:

- Distance ≤ 0.05 → auto-accepted, file moved to `~/Music/library/`
- Distance > 0.05 → skipped, file left in inbox, quarantined by the script

0.05 is strict — only very close MusicBrainz matches pass automatically. Raise to 0.10 if too many valid tracks end up in quarantine.

### File layout

```
~/Music/library/<albumartist>/<album>/<track> - <title>.<ext>
~/Music/library/Various Artists/<album>/<track> - <title>.<ext>   ← compilations
```

### Plugins in use

| Plugin | What it does |
|--------|-------------|
| `fromfilename` | Guesses tags from filename when no tags exist |
| `fetchart` | Downloads album art from the web |
| `embedart` | Embeds downloaded art into the audio file |
| `scrub` | Strips extraneous tags before import |
| `duplicates` | Detects duplicate tracks in the library |

### Skipped files log

```bash
cat ~/.config/beets/import.log
```

Every skipped track is recorded here with the reason.

---

## Playlists

`music-ingest` generates one `.m3u` per playlist in `~/Music/playlists/`. Paths inside the `.m3u` are relative to the playlists directory (e.g. `../library/Artist/Album/01 - Track.m4a`), which is required for Navidrome compatibility.

---

## Navidrome integration

Navidrome auto-imports `.m3u` files found inside the configured music folder. Point Navidrome at `~/Music/` (not `~/Music/library/`) so it can see both the library and the playlists directory.

Enable playlist auto-import:

```
ND_AUTOIMPORTPLAYLISTS=true
```

Navidrome imports playlists after an admin user exists and after the initial library scan completes. For large libraries this can take 15+ minutes on first run. To force a reimport after updating a playlist:

```bash
touch ~/Music/playlists/*.m3u
```

Then trigger a rescan in the Navidrome UI.

---

## Useful beets commands

```bash
beet stats                          # library summary
beet ls source:liked-songs          # list all tracks from a specific playlist
beet ls -a                          # list all albums
beet ls 'added: 2025..'             # tracks added this year
beet modify -y field=value query    # set a field on matching tracks
cat ~/.config/beets/import.log      # see skipped imports
```

---

## File summary

```
dotfiles/
  beets/
    .config/beets/
      config.yaml          ← beets config; plugins, paths, match threshold
  spotdl/
    .spotdl/
      config.json          ← format: m4a, bitrate: disable
  music/
    .local/bin/
      music-setup          ← add a playlist (run once per playlist)
      music-ingest         ← daily sync; download → import → m3u → quarantine → prune
      music-import         ← import inbox drops; called by music-ingest, also standalone

~/.spotdl/
  config.json              ← symlink to dotfiles; format: m4a, bitrate: disable
~/.config/spotdl/
  cookies.txt              ← YouTube Premium cookies (required; not committed)
~/Music/
  inbox/spotdl/
    <name>.spotdl          ← spotdl sync state (do not delete)
    <name>/                ← spotdl download dir per playlist
  inbox/                   ← drop albums here; picked up by music-import
  library/                 ← beets-managed files
  quarantine/              ← awaiting manual tag fixes
  playlists/               ← generated .m3u files (one per playlist)
~/.config/beets/
  library.db               ← beets SQLite database
  import.log               ← log of every skipped import
```
