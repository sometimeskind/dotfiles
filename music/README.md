# Music Library Pipeline

A self-hosted music pipeline: Spotify liked songs → local M4A files → beets-managed library → Navidrome.

## Packages

Three dotfiles packages work together:

| Package | Stow target | Purpose |
|---------|-------------|---------|
| `beets` | `~/.config/beets/config.yaml` | Library management, tag fixing, playlist generation |
| `spotdl` | `~/.config/spotdl/config.json` | Download quality settings |
| `music` | `~/.local/bin/music-{setup,ingest,bulk-import}` | Pipeline scripts |

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
stow beets spotdl music
```

Ensure the scripts are executable:

```bash
chmod +x ~/.local/bin/music-setup ~/.local/bin/music-ingest ~/.local/bin/music-bulk-import
```

### 2. Run setup

```bash
music-setup
```

This creates the directory structure and initialises the spotdl sync file:

```
~/Music/
  inbox/
    spotdl/          ← spotdl downloads land here
      favorites.spotdl   ← sync state; do not delete
  library/           ← beets-managed, tagged files
  quarantine/        ← low-confidence imports awaiting manual review
  playlists/         ← generated .m3u files
```

You will be prompted for your Spotify liked songs playlist URL. To get it:
Spotify → Your Library → Liked Songs → Share → Copy Link

### 3. YouTube Premium cookies (optional, for higher quality)

Without cookies, spotdl downloads at 128 kbps. With a YouTube Premium account and cookies, it downloads M4A at up to 256 kbps (no re-encoding, original quality).

1. Install the **"Get cookies.txt LOCALLY"** browser extension (Chrome or Firefox)
2. Go to `https://music.youtube.com` while logged in
3. Export cookies in **Netscape format**
4. Save the file to `~/.config/spotdl/cookies.txt`

The scripts detect this file automatically — no config changes needed. The file is not committed to the dotfiles repo (it is personal and rotates over time).

> **Note:** YouTube cookies expire. If downloads start failing or quality degrades, re-export and overwrite `~/.config/spotdl/cookies.txt`.

---

## Ongoing use

### Sync liked songs

```bash
music-ingest
```

Runs the full pipeline:

1. `spotdl sync` — downloads any liked songs not yet on disk into `~/Music/inbox/spotdl/`
2. `beet import --set source=spotdl` — queries MusicBrainz, auto-accepts high-confidence matches, copies files into `~/Music/library/`
3. `beet import` — imports anything manually dropped into `~/Music/inbox/`
4. Quarantine sweep — audio files left in inbox (beets skipped them) are moved to `~/Music/quarantine/`
5. `beet update` / `beet remove` — prunes library entries for files that no longer exist
6. `smartplaylist` regenerates `~/Music/playlists/spotify-likes.m3u`

### Manual file adds

Drop any audio file into `~/Music/inbox/`, then run `music-ingest`. It will be imported and tagged like any other file. It will **not** appear in `spotify-likes.m3u` (that playlist only includes tracks tagged `source=spotdl`).

### Bulk import an existing collection (one-time)

```bash
music-bulk-import /path/to/existing/music
```

Imports what beets can confidently match; moves the rest to `~/Music/quarantine/`. Does not tag tracks with `source=spotdl`.

---

## Quarantine workflow

Low-confidence MusicBrainz matches are moved to `~/Music/quarantine/` rather than being silently imported with bad tags.

To process them:

1. Open `~/Music/quarantine/` in **MusicBrainz Picard**
2. Look up and fix tags manually
3. Save the files back to `~/Music/quarantine/` (Picard can move them in place)
4. Run `music-ingest` — beets will re-attempt import with the corrected tags

> **Note:** After Picard saves files they may have moved within the quarantine folder. `music-ingest` scans up to 10 levels deep in `~/Music/inbox/spotdl/` but only 1 level deep in `~/Music/inbox/`. The quarantine folder is not re-scanned automatically — manually move fixed files to `~/Music/inbox/` if needed.

---

## How beets works

### Match threshold

`config.yaml` sets `strong_rec_thresh: 0.10`. Beets scores MusicBrainz matches 0–1:

- Score ≥ 0.10 → auto-accepted, file copied to `~/Music/library/`
- Score < 0.10 → skipped, file left in inbox, quarantined by the script

Raising this threshold means stricter matching (more quarantine). Lowering it means more auto-accepts (potentially messier metadata). 0.10 is permissive; tighten to 0.15–0.20 if you find bad tags getting through.

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
| `smartplaylist` | Generates `.m3u` playlists from beets queries |

### Skipped files log

```bash
cat ~/.config/beets/import.log
```

Every skipped track is recorded here with the reason.

---

## Playlists

`~/Music/playlists/spotify-likes.m3u` is regenerated automatically after every `music-ingest` run. It contains every track tagged `source=spotdl` — i.e., everything downloaded from your Spotify liked songs.

Paths inside the `.m3u` are relative to the playlists directory (e.g. `../library/Artist/Album/01 - Track.m4a`). This is required for Navidrome compatibility.

### Adding more playlists

Edit `~/.config/beets/config.yaml` and add entries under `smartplaylist.playlists`. Any beets query works:

```yaml
playlists:
  - name: spotify-likes.m3u
    query: source:spotdl
  - name: recent.m3u
    query: 'added: 2025..'
  - name: hifi.m3u
    query: 'format:FLAC'
```

Regenerate immediately (without a full ingest):

```bash
beet splupdate
```

### Backfilling existing tracks

Tracks imported before `source=spotdl` tagging was added won't appear in the playlist. Backfill with:

```bash
beet modify -y source=spotdl path:~/Music/library/
```

Use a tighter query if you have non-spotdl tracks in the library you want to exclude.

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

> **Caveat:** Navidrome resolves paths relative to the `.m3u` file location. If you ever move the playlists directory, update `smartplaylist.relative_to` in `config.yaml` to match and regenerate with `beet splupdate`.

---

## Useful beets commands

```bash
beet stats                          # library summary
beet ls source:spotdl               # list all spotdl tracks
beet ls -a                          # list all albums
beet ls 'added: 2025..'             # tracks added this year
beet modify -y field=value query    # set a field on matching tracks
beet splupdate                      # regenerate all smartplaylists
cat ~/.config/beets/import.log      # see skipped imports
```

---

## File summary

```
dotfiles/
  beets/
    .config/beets/
      config.yaml          ← beets config; plugins, paths, smartplaylists
  spotdl/
    .config/spotdl/
      config.json          ← format: m4a, bitrate: disable
  music/
    .local/bin/
      music-setup          ← first-time setup; creates dirs, initialises spotdl
      music-ingest         ← daily sync; download → import → quarantine → prune
      music-bulk-import    ← one-time import of an existing collection

~/.config/spotdl/
  cookies.txt              ← YouTube Premium cookies (not committed; optional)
~/Music/
  inbox/spotdl/
    favorites.spotdl       ← spotdl sync state (do not delete)
  library/                 ← beets-managed files
  quarantine/              ← awaiting manual tag fixes
  playlists/               ← generated .m3u files
~/.config/beets/
  library.db               ← beets SQLite database
  import.log               ← log of every skipped import
```
