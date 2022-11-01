#!/bin/bash

check-and-load() {
    if [ ! -f "$1" ]; then
        echo "Unable to locate file $1, aborting!"
        exit
    else
        source "$1"
    fi
}

check-and-load "/opt/mc-backup/assets/constants.sh"

if [ -f "$ENV_FILE" ]; then
    check-and-load "$ENV_FILE"
fi

check-and-load "$ASSETS_FOLDER/log.sh"
check-and-load "$ASSETS_FOLDER/rcon.sh"
check-and-load "$ASSETS_FOLDER/pack-data.sh"
check-and-load "$ASSETS_FOLDER/manage-data.sh"

log-debug "Dependencies loaded!"

acquire-lock() {
    # Checking if backup/restore is already running
    if [ -f "$PID_FILE" ]; then
        if ps -p $(cat $PID_FILE) >/dev/null 2>&1; then
        log-fatal "Backup or restore already running!"
        exit 1
        fi
    fi
    echo $$ > "$PID_FILE"
}

release-lock() {
    close-rcon
    rm "$PID_FILE"
    exit 0
}