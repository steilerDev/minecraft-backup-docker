#!/bin/bash

# DON'T EXECUTE THIS FILE DIRECTLY

check-disk-space () {
    # Maybe just take the actual world size and see if this x2 would fit. 1x for the tar and another for the xz

    # Check if there is enough disk space
    NUM_BACKUPS=$(find $HISTORY_DATA_DIR -type f | wc -l)
    if [ "$NUM_BACKUPS" -gt "0" ]; then

        TOTAL_DISK_USAGE=$(du -b --max-depth=0 "$HISTORY_DATA_DIR" | awk '{print $1}')
        AVAILABLE_DISK_SPACE=$(df "$HISTORY_DATA_DIR"  | awk 'NR==2{print $4}')
        AVAILABLE_DISK_SPACE_BYTES=$((AVAILABLE_DISK_SPACE*1024))
        AVG_BACKUP_SIZE=$((( $TOTAL_DISK_USAGE / $NUM_BACKUPS ) / (1024 * 1024) ))

        if [ "$AVAILABLE_DISK_SPACE_BYTES" -lt "$AVG_BACKUP_SIZE" ]; then
            log-fatal "Not enough disk space ($(df -h "$HISTORY_DATA_DIR"  | awk 'NR==2{print $4}') available)"
        else
            log-debug "Disk check passed: Average Backup Size ($AVG_BACKUP_SIZE MB, over $NUM_BACKUPS backups) is smaller than remaining disk space ($(df -h "$HISTORY_DATA_DIR"  | awk 'NR==2{print $4}'))"
            log-debug "Currently consuming $(( $TOTAL_DISK_USAGE / (1024 * 1024))) MB"
        fi
    else
        log-debug "This is the initial backup, $(df -h "$HISTORY_DATA_DIR"  | awk 'NR==2{print $4}') available"
    fi
}

pack-data () {
    log-info "Packing backup data..."
    BACKUP_ARCHIVE="${HISTORY_DATA_DIR}/latest.tar"
    
    START_TIME=$(date +"%s") 
    # Stop world autosaving
    execute-command "save-off"
    sync -f "$BACKUP_SOURCE"

    tar -cf "$BACKUP_ARCHIVE" -C "$BACKUP_SOURCE" .
    TAR_EXIT_CODE=$?
    # tar exit codes: http://www.gnu.org/software/tar/manual/html_section/Synopsis.html
    # 0 = successful, 1 = some files differ, 2 = fatal
    if [ $TAR_EXIT_CODE -eq 1 ]; then
      log-warn "Some files may differ in the backup archive (file changed as read)"
    elif [ $TAR_EXIT_CODE -ne 0 ]; then
      log-fatal "Archive command exited with nonzero exit code $TAR_EXIT_CODE"
    fi

    # Re-enable world autosaving
    execute-command "save-on"

    # Save the world
    execute-command "save-all"

    # Getting the actual creation time
    MINUTE=$(date -r ${BACKUP_ARCHIVE} -u +%M)
    HOUR=$(date -r ${BACKUP_ARCHIVE} -u +%H)
    DAY=$(date -r ${BACKUP_ARCHIVE} -u +%d)
    WEEK=$(date -r ${BACKUP_ARCHIVE} -u +%V)
    MONTH=$(date -r ${BACKUP_ARCHIVE} -u +%m)
    YEAR=$(date -r ${BACKUP_ARCHIVE} -u +%Y)

    log-info "Compressing archive..."
    sync -f "$BACKUP_ARCHIVE"

    xz -0 -f ${BACKUP_ARCHIVE}
    BACKUP_ARCHIVE=${BACKUP_ARCHIVE}.xz

    sync -f "$BACKUP_ARCHIVE"

    log-info "Succesfully packed backup data!"
}

analyze-backup () {
  WORLD_SIZE_BYTES=$(du -b --max-depth=0 "$BACKUP_SOURCE" | awk '{print $1}')
  ARCHIVE_SIZE_BYTES=$(du -b "$BACKUP_ARCHIVE" | awk '{print $1}')
  COMPRESSION_PERCENT=$((100 - ( ARCHIVE_SIZE_BYTES * 100 / WORLD_SIZE_BYTES)))
  ARCHIVE_SIZE=$(du -h "$BACKUP_ARCHIVE" | awk '{print $1}')
  NUM_BACKUPS=$(find $HISTORY_DATA_DIR -type f | wc -l)
  TOTAL_DISK_USAGE=$(du -h --max-depth=0 "$HISTORY_DATA_DIR" | awk '{print $1}')
  AVAILABLE_DISK_SPACE=$(df -h "$HISTORY_DATA_DIR"  | awk 'NR==2{print $4}')

  # Check that archive size is not null and at least 200 Bytes
  if [[ $ARCHIVE_SIZE_BYTES -lt 200 ]]; then
    log-warn "Backup size is very small ($ARCHIVE_SIZE_BYTES Bytes)"
  fi
  END_TIME=$(date +"%s")
  TIME_DELTA=$((END_TIME - START_TIME))
}