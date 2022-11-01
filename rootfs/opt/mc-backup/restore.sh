#!/bin/bash
source "/opt/mc-backup/assets/load-dependencies.sh"
acquire-lock

DIAG_HEIGHT=$(if command -v tput >/dev/null 2>&1; then echo $(expr $(tput lines) - 10); else echo 15; fi)
DIAG_WIDTH=$(if command -v tput >/dev/null 2>&1; then echo $(expr $(tput cols) - 20); else echo 80; fi)

RESTORE_DIR=$(mktemp -d)
TMP_FILE=$(mktemp)

dialog --title "Please select backup to restore" --fselect $HISTORY_DATA_DIR/ $DIAG_HEIGHT $DIAG_WIDTH 2> $TMP_FILE
echo
echo

SELECTION=$(cat $TMP_FILE)

if [ -z "$SELECTION" ]; then
    echo "No selection"
    exit
elif [ ! -f "$SELECTION" ]; then
    echo "No such file"
    exit
else
    RESTORE_DESC=$(basename "$SELECTION" .tar.xz)
    # rcon.sh
    login
    log-status "Starting to restore old backup: Server will reset to $RESTORE_DESC soon!"
    log-info "Creating restore point..."

    pack-data

    log-debug "Moving restore point..."
    FILE="$HISTORY_DIR/restored/${YEAR}-${MONTH}-${DAY}_${HOUR}-${MINUTE}.tar.xz"
    mv "$BACKUP_ARCHIVE" "$FILE"

    log-debug "Extracting backup $SELECTION..."
    tar -x -f "$SELECTION" --same-owner -C "$RESTORE_DIR"
    # Cleaning dirty flag in backup
    rm "$RESTORE_DIR/session.lock"

    SIZE=$(du -sB 1 $RESTORE_DIR | cut -f1)
    if [[ $SIZE -lt 10000000 ]]; then
        log-fatal "Restore directory seems too small ($(du -hs $RESTORE_DIR)), aborting!"
        rm -r "$FILE"
    else
        log-status "Server will go down in 10 seconds, in order to reset to $RESTORE_DESC"
        log-status "Expect the server to be offline for 1-2 minutes"
        sleep 10

        LOGGED_IN=false
        log-info "Stopping server now!"
        docker stop "$MC_DOCKER" > /dev/null 2>&1
        #execute-command "stop"

        log-debug "Removing old world ($BACKUP_SOURCE)"
        rm -rf "$BACKUP_SOURCE"/*

        log-debug "Restoring from backup ($RESTORE_DIR) to world save ($BACKUP_SOURCE)"
        mv "${RESTORE_DIR}"/* "$BACKUP_SOURCE"/

        log-info "Restarting server..."
        docker start "$MC_DOCKER" > /dev/null 2>&1
    fi
    
    log-debug "Removing $RESTORE_DIR and $TMP_FILE"
    rm -r "$RESTORE_DIR" "$TMP_FILE"
    log-status "Restore Complete!"
fi

# load-dependencies.sh
release-lock