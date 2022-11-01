#!/bin/bash
source "/opt/mc-backup/assets/load-dependencies.sh"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
UNDERLINE='\e[4m'
STOP_UNDERLINE='\e[0m'
STOP_COLOR='\033[0m'

echo -e "${BLUE}############${GREEN} Minecraft Backup Status ${BLUE}##########################################"
echo -e "${BLUE}###############################################################################"

FILLER="                                                                        "
if [ ! -f $STATUS_FILE ]; then
    STATUS="Unable to find status file!"
else
    STATUS="$(cat $STATUS_FILE)"
fi
STATUS="${STATUS:0:72}${FILLER:0:$((72 - ${#STATUS}))}"

echo -e "${BLUE}##  ${YELLOW}${STATUS}${BLUE} ##"
echo -e "${BLUE}###############################################################################${STOP_COLOR}"
