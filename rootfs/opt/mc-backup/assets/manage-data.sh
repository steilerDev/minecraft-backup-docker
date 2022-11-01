#!/bin/bash

link-backup () {
    # Moving the actual file somewhere safe
    FILE="$HISTORY_DATA_DIR/${YEAR}-${MONTH}-${DAY}_${HOUR}-${MINUTE}.tar.xz"
    mv "$BACKUP_ARCHIVE" "$FILE"

    ln -f "${FILE}" "${HISTORY_DIR}/by-hour/hour_${YEAR}-${MONTH}-${DAY}_${HOUR}.tar.xz" 
    ln -f "${FILE}" "${HISTORY_DIR}/by-day/day_${YEAR}-${MONTH}-${DAY}.tar.xz" 
    ln -f "${FILE}" "${HISTORY_DIR}/by-week/week_${YEAR}-W${WEEK}.tar.xz" 
    ln -f "${FILE}" "${HISTORY_DIR}/by-month/month_${YEAR}-${MONTH}.tar.xz" 
    ln -f "${FILE}" "${HISTORY_DIR}/by-year/year_${YEAR}.tar.xz" 
    
    log-debug "Linked backup $FILE"
}

appy-data-retention () {
    log-info "Applying data retention policy..."
    # Removing all entries but the n-th most recent (if not specified they will be kept forever)
    if [ ! -z $KEEP_HOURLY ]; then 
        ls -tp "${HISTORY_DIR}/by-hour/" | grep -v '/$' | tail -n +$((KEEP_HOURLY+1)) | while IFS= read -r f; do 
            log-debug "$f is too old, will be deleted"; 
            rm "${HISTORY_DIR}/by-hour/$f"
        done
    fi

    if [ ! -z $KEEP_DAILY ]; then 
        ls -tp "${HISTORY_DIR}/by-day/" | grep -v '/$' | tail -n +$((KEEP_DAILY+1)) | while IFS= read -r f; do 
            log-debug "$f is too old, will be deleted"; 
            rm "${HISTORY_DIR}/by-day/$f"
        done
    fi

    if [ ! -z $KEEP_WEEKLY ]; then 
        ls -tp "${HISTORY_DIR}/by-week/" | grep -v '/$' | tail -n +$((KEEP_WEEKLY+1)) | while IFS= read -r f; do 
            log-debug "$f is too old, will be deleted"; 
            rm "${HISTORY_DIR}/by-week/$f"
        done
    fi

    if [ ! -z $KEEP_MONTHLY ]; then 
        ls -tp "${HISTORY_DIR}/by-month/" | grep -v '/$' | tail -n +$((KEEP_MONTHLY+1)) | while IFS= read -r f; do 
            log-debug "$f is too old, will be deleted"; 
            rm "${HISTORY_DIR}/by-month/$f"
        done
    fi

    if [ ! -z $KEEP_YEARLY ]; then 
        ls -tp "${HISTORY_DIR}/by-year/" | grep -v '/$' | tail -n +$((KEEP_YEARLY+1)) | while IFS= read -r f; do 
            log-debug "$f is too old, will be deleted"; 
            rm "${HISTORY_DIR}/by-year/$f"
        done
    fi

    log-debug "Purging old backups..."    
    # Now that all links are deleted that are no longer relevant, we delete the files that are no longer referenced, but by themself
    NUM_DELETED_FILES=$(find ${HISTORY_DATA_DIR} -links 1 | wc -l)
    find ${HISTORY_DATA_DIR} -links 1 -exec rm {} \;
    log-info "Purged $NUM_DELETED_FILES backups"
}

print-retention-policy () {
    log-info "Retention policy:"
    if [ -z $KEEP_HOURLY ]; then
        log-info "Keep all hourly backups"
    else
        log-info "Keep last $KEEP_HOURLY hourly backup(s)"
    fi

    if [ -z $KEEP_DAILY ]; then
        log-info "Keep all daily backups"
    else
        log-info "Keep last $KEEP_DAILY daily backup(s)"
    fi

    if [ -z "$KEEP_WEEKLY" ]; then
        log-info "Keep all weekly backups"
    else
        log-info "Keep last $KEEP_WEEKLY weekly backup(s)"
    fi

    if [ -z "$KEEP_MONTHLY" ]; then
        log-info "Keep all monthly backups"
    else
        log-info "Keep last $KEEP_MONTHLY backup(s)"
    fi

    if [ -z "$KEEP_YEARLY" ]; then
        log-info "Keep all yearly backups"
    else
        log-info "Keep last $KEEP_YEARLY backup(s)"
    fi
}
