music_pipeline := "~/src/music-pipeline"

# Run full ingest (download + import + M3U + quarantine)
sync:
    op run --env-file {{music_pipeline}}/.env.tpl -- docker compose -f {{music_pipeline}}/compose.yml exec pipeline music-ingest

# Add a new playlist (interactive)
setup:
    op run --env-file {{music_pipeline}}/.env.tpl -- docker compose -f {{music_pipeline}}/compose.yml exec -it pipeline music-setup

# Remove a playlist: just remove <name>
remove name:
    docker compose -f {{music_pipeline}}/compose.yml exec pipeline music-remove {{name}}

# Import files dropped into inbox
import:
    docker compose -f {{music_pipeline}}/compose.yml exec pipeline music-import

# Trigger Navidrome library rescan
# TODO: fill in Navidrome host, user, and password (store password in 1Password)
# rescan:
#     curl -s "http://<navidrome-host>/rest/startScan?u=<user>&p=<pass>&v=1.16.1&c=music-pipeline&f=json"

# Tail container logs
logs:
    docker compose -f {{music_pipeline}}/compose.yml logs -f pipeline

# Start the pipeline container
up:
    op run --env-file {{music_pipeline}}/.env.tpl -- docker compose -f {{music_pipeline}}/compose.yml up -d

# Stop the pipeline container
down:
    docker compose -f {{music_pipeline}}/compose.yml down

# Dump beets DB and export JSON from the container
backup:
    docker compose -f {{music_pipeline}}/compose.yml exec pipeline sh -c \
        "beet export > /root/.config/beets/library-export.json && \
         sqlite3 /root/.config/beets/library.db .dump > /root/.config/beets/library-dump.sql"
