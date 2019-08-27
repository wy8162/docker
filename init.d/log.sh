#!/bin/bash

# Usage: log <message>
function log {
    logfile="/dev/stdout"

    if [ -d /opt/log ]; then
        logfile="/opt/log/$(hostname -s).log"
    fi
    echo "startd $(date +%X) ==> $1" >> "${logfile}"
}