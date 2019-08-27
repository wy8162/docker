#!/bin/bash
# Yang Wang
#
# Container oracle11gr2 start script.
#

source /opt/init.d/ora11gr2/oracle_constants.sh
source /opt/init.d/log.sh

logfile="/dev/stdout"

    if [ -d /opt/log ]; then
        logfile="/opt/log/$(hostname -s).log"
    fi

function cleanUp {
    service oracle stop
    exit
}

if [[ -e $ORACLE_HOME/bin/dbca && -e $ORACLE_HOME/bin/netca && -e /etc/init.d/oracle ]]; then
    log "Oracle has already been installed"
else
    log "Installing Oracle Database 11g R2..."
    cd /opt/init.d/ora11gr2
    ./installoracle11gr2.sh >> "${logfile}"
fi

if [[ -e $ORACLE_HOME/bin/dbca && -e $ORACLE_HOME/bin/netca && -e /etc/init.d/oracle ]]; then
    log "Oracle has already been installed"
else
    log "Starting failed. Oracle not installed or failed to be installed."
    exit 1
fi

trap cleanUp SIGHUP SIGINT SIGTERM

while :
do
    tnsp=$(su - $ORACLE_U_USER -c "tnsping develop 5")
    if [[ ! $tnsp = *OK* ]]; then
        log "Starting Oracle service..."
        service oracle start
    else
        log "Oracle is running"
    fi

    # Sleep 10 seconds.
    sleep 10
done

# Done.
