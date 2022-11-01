#!/bin/bash
source "/opt/mc-backup/assets/load-dependencies.sh"
acquire-lock

# pack-data.sh
check-disk-space

# rcon.sh
login
log-status "Backup starting now"

# pack-data.sh
pack-data
analyze-backup

# manage-data.sh
link-backup
appy-data-retention

log-status "Backup succesfully finished"
if [ ! -z "$LOG_RCON" ]; then
    log-info "Stored $ARCHIVE_SIZE ($COMPRESSION_PERCENT% compressed) in $TIME_DELTA second(s)"
    log-info "Purged $NUM_DELETED_FILES outdated backup(s), now holding $NUM_BACKUPS backup(s)"
    log-info "Total backup disk usage $TOTAL_DISK_USAGE with $AVAILABLE_DISK_SPACE available"
fi

# load-dependencies.sh
release-lock