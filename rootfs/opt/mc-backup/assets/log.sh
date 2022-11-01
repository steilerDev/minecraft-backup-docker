#!/bin/bash

DATE_FORMAT="%Y-%m-%d %H:%M"

log-fatal () {
    echo -e "\033[0;31m[$(date +"$DATE_FORMAT")] [FATAL]:\033[0m $*"
    if [ ! -z "$LOG_RCON" ] && [ "$LOGGED_IN" = true ]; then
        message-color "red" "$LOG_RCON" "[FATAL] $*"
    fi
    exit 1
}

log-warn () {
    echo -e "\033[0;33m[$(date +"$DATE_FORMAT")] [WARN]:\033[0m $*"
    if [ ! -z "$LOG_RCON" ] && [ "$LOGGED_IN" = true ]; then
        message-color "orange" "$LOG_RCON" "[WARN] $*"
    fi
}

log-info () {
    echo -e "\033[0;33m[$(date +"$DATE_FORMAT")] [INFO]:\033[0m $*"
    if [ ! -z "$LOG_RCON" ] && [ "$LOGGED_IN" = true ]; then
        message "$LOG_RCON" "[INFO] $*"
    fi
}

log-debug () {
  if [ ! -z "$DEBUG" ]; then
    echo -e "\033[0;37m[$(date +"$DATE_FORMAT")] [DEBUG]:\033[0m $*"
  fi
}

log-status () {
    echo -e "\033[0;32m[$(date +"$DATE_FORMAT")] [STATUS]:\033[0m $*"
    echo "$* at $(date)" > $STATUS_FILE
    if [ "$LOGGED_IN" = true ]; then
        message-color "green" "@a" "$1"
    fi
}
