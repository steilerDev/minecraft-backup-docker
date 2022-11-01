#!/bin/bash
source "/opt/mc-backup/assets/load-dependencies.sh"

handle-stop () {
    echo "Received stop signal..."
    kill -9 $$
}

trap handle-stop SIGTERM

log-info "Welcome to steilerGroup-Minecraft-Backup Docker!"

exec 3<&-
exec 3>&-

log-debug "Applying environmental variables..."
> $ENV_FILE

if [ -z "$RCON_PASSWORD" ]; then
    log-fatal "RCON password not defined!"
else
    echo "RCON_PASSWORD=\"$RCON_PASSWORD\"" >> $ENV_FILE
fi

if [ -z "$RCON_HOST" ]; then
    log-fatal "RCON host not defined!"
else
    echo "RCON_HOST=\"$RCON_HOST\"" >> $ENV_FILE
fi

echo "RCON_PORT=\"${RCON_PORT:-25575}\"" >> $ENV_FILE
echo "RCON_PREFIX=\"${RCON_PREFIX:-BOT}\"" >> $ENV_FILE 
echo "KEEP_HOURLY=\"$KEEP_HOURLY\"" >> $ENV_FILE
echo "KEEP_DAILY=\"$KEEP_DAILY\"" >> $ENV_FILE
echo "KEEP_WEEKLY=\"$KEEP_WEEKLY\"" >> $ENV_FILE
echo "KEEP_MONTHLY=\"$KEEP_MONTHLY\"" >> $ENV_FILE
echo "KEEP_YEARLY=\"$KEEP_YEARLY\"" >> $ENV_FILE
echo "DEBUG=${DEBUG:-false}" >> $ENV_FILE
echo "LOG_RCON=\"$LOG_RCON\"" >> $ENV_FILE
echo "MC_DOCKER=\"$MC_DOCKER\"" >> $ENV_FILE

source $ENV_FILE

if [ ! -f $STATUS_FILE ]; then
    echo "No backup run yet" > $STATUS_FILE
fi

# Creating directory tree, if not happened
mkdir -p  "${HISTORY_DIR}/restored" "${HISTORY_DIR}/by-hour" "${HISTORY_DIR}/by-day" "${HISTORY_DIR}/by-week" "${HISTORY_DIR}/by-month" "${HISTORY_DIR}/by-year" "$HISTORY_DATA_DIR"

log-debug "Setting up cron-job..."
CRON_FILE="/etc/cron.d/backup"
> $CRON_FILE
echo "$CRON_SCHEDULE root /mc-backup/backup.sh > /proc/1/fd/1 2>/proc/1/fd/2" >> $CRON_FILE
echo "" >> $CRON_FILE
chmod 0644 $CRON_FILE

log-info "Starting scheduled backup process with cron schedule $CRON_SCHEDULE"
print-retention-policy
cron -f
