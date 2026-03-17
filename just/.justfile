music_image := "ghcr.io/sometimeskind/music-pipeline"
music_env   := "~/.config/music-pipeline/.env"
container   := "pipeline"

# Run full ingest (download + import + M3U + quarantine)
sync:
    op run --env-file {{music_env}} -- docker exec {{container}} music-ingest

# Add a new playlist (interactive)
setup:
    op run --env-file {{music_env}} -- docker exec -it {{container}} music-setup

# Remove a playlist: just remove <name>
remove name:
    docker exec {{container}} music-remove {{name}}

# Import files dropped into inbox
import:
    docker exec {{container}} music-import

# Trigger Navidrome library rescan
# TODO: fill in Navidrome host, user, and password (store password in 1Password)
# rescan:
#     curl -s "http://<navidrome-host>/rest/startScan?u=<user>&p=<pass>&v=1.16.1&c=music-pipeline&f=json"

# Tail container logs
logs:
    docker logs -f {{container}}

# Start the pipeline container
up:
    docker pull {{music_image}}
    op run --env-file {{music_env}} -- docker run -d --name {{container}} --restart unless-stopped \
        -v ~/Music:/root/Music \
        -v ~/.config/beets:/root/.config/beets \
        -v ~/.config/spotdl:/root/.config/spotdl \
        {{music_image}}

# Stop the pipeline container
down:
    docker rm -f {{container}}

# Dump beets DB and export JSON from the container
backup:
    docker exec {{container}} sh -c \
        "beet export > /root/.config/beets/library-export.json && \
         sqlite3 /root/.config/beets/library.db .dump > /root/.config/beets/library-dump.sql"
