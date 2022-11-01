#!/bin/bash

# DON'T EXECUTE THIS FILE DIRECTLY

LOGGED_IN=false

reverse-hex-endian () {
    # Given a 4-byte hex integer, reverse endianness
    while read -r -d '' -N 8 INTEGER; do
      echo "$INTEGER" | sed -E 's/(..)(..)(..)(..)/\4\3\2\1/'
    done
}

decode-hex-int () {
    # decode little-endian hex integer
    while read -r -d '' -N 8 INTEGER; do
      BIG_ENDIAN_HEX=$(echo "$INTEGER" | reverse-hex-endian)
      echo "$((16#$BIG_ENDIAN_HEX))"
    done
}

stream-to-hex () {
    xxd -ps
}

hex-to-stream () {
    xxd -ps -r
}

encode-int () {
    # Encode an integer as 4 bytes in little endian and return as hex
    INT="$1"
    # Source: https://stackoverflow.com/a/9955198
    printf "%08x" "$INT" | sed -E 's/(..)(..)(..)(..)/\4\3\2\1/' 
}

encode () {
    # Encode a packet type and payload for the rcon protocol
    TYPE="$1"
    PAYLOAD="$2"
    REQUEST_ID="$3"
    PAYLOAD_LENGTH="${#PAYLOAD}" 
    TOTAL_LENGTH="$((4 + 4 + PAYLOAD_LENGTH + 1 + 1))"

    OUTPUT=""
    OUTPUT+=$(encode-int "$TOTAL_LENGTH")
    OUTPUT+=$(encode-int "$REQUEST_ID")
    OUTPUT+=$(encode-int "$TYPE")
    OUTPUT+=$(echo -n "$PAYLOAD" | stream-to-hex)
    OUTPUT+="0000"

    echo -n "$OUTPUT" | hex-to-stream 
}

read-response () {
    # read next response packet and return the payload text
    HEX_LENGTH=$(head -c4 <&3 | stream-to-hex | reverse-hex-endian)
    LENGTH=$((16#$HEX_LENGTH))

    RESPONSE_PAYLOAD=$(head -c $LENGTH <&3 | stream-to-hex)
    echo -n "$RESPONSE_PAYLOAD"
}

response-request-id () {
    echo -n "${1:0:8}" | decode-hex-int
}

response-type () {
    echo -n "${1:8:8}" | decode-hex-int
}

response-payload () {
    echo -n "${1:16:-4}" | hex-to-stream
}

login () {
    # Open a TCP socket
    # Source: https://www.xmodulo.com/tcp-udp-socket-bash-shell.html
    if ! exec 3<>/dev/tcp/"$RCON_HOST"/"$RCON_PORT"; then
        log-fatal "RCON connection failed: Could not connect to $RCON_HOST:$RCON_PORT"
    fi

    encode 3 "$RCON_PASSWORD" 12 >&3

    RESPONSE=$(read-response "$IN_PIPE")

    RESPONSE_REQUEST_ID=$(response-request-id "$RESPONSE")
    if [[ "$RESPONSE_REQUEST_ID" == "-1" ]] || [[ "$RESPONSE_REQUEST_ID" == "4294967295" ]]; then
        log-fatal "RCON connection failed: Wrong RCON password" 1>&2
    else
        LOGGED_IN=true
    fi
}

execute-command () {
    COMMAND="$1"

    if [ "$LOGGED_IN" = true ] ; then
    # encode 2 "$COMMAND" 13 >> "$OUT_PIPE"
        encode 2 "$COMMAND" 13 >&3
        RESPONSE=$(read-response "$IN_PIPE")
        RESPONSE_TEXT="$(response-payload "$RESPONSE")"
        if [ ! -z "$RESPONSE_TEXT" ]; then
            log-debug "[RCON] $RESPONSE_TEXT"
        fi
    else 
        echo "Not executing command $COMMAND, rcon not logged in!"
    fi
}

# Minecraft server screen interface functions
message () {
    local TO=$1
    local MESSAGE=$2
#    local HOVER_MESSAGE=$3
    message-color "gray" "$TO" "$MESSAGE" # "$HOVER_MESSAGE"
}

message-color () {
    local COLOR=$1
    local TO=$2
    local MESSAGE=$3
#    local HOVER_MESSAGE=$4

#    if [ -z "$HOVER_MESSAGE" ]; then
        execute-command "tellraw $TO [\"\",{\"text\":\"[$RCON_PREFIX] \",\"color\":\"gray\",\"italic\":true},{\"text\":\"$MESSAGE\",\"color\":\"$COLOR\",\"italic\":true}]"
#    else
#        log-debug "Sending message with hover text"
#        execute-command "tellraw $TO [\"\",{\"text\":\"[$RCON_PREFIX] \",\"color\":\"gray\",\"italic\":true},{\"text\":\"$MESSAGE\",\"color\":\"$COLOR\",\"italic\":true,\"hoverEvent\":{\"action\":\"show_text\",\"contents\":{\"text\":\"$HOVER_MESSAGE\"}}}]"
#    fi
}


close-rcon () {
    if [ "$LOGGED_IN" = true ]; then
        log-debug "Closing rcon socket, good bye!"
        exec 3<&-
        exec 3>&-
        LOGGED_IN=false
    fi
}

trap "close-rcon" 2
