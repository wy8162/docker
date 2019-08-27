#!/bin/bash
# Yang Wang
#
# This scrip serves as the start command for containers. It'll search a file named "hostname.run.sh"
# under /opt/init.d and runs it if it exists. The `hostname.run.sh` will decide what to do. It'll run the command
# as user root. So it's the script's responsibility to use the correct user name to run the commands.
#
# This will give it a chance to run a one-shot task like installing Oracle 11g R2. It can check if Oracle
# has already been installed. If installed, it should go ahead to run the Oracle service.
#
source /opt/init.d/log.sh

hn=$(hostname -s)
runnableScript="${hn}.run.sh"

if [ -e "/opt/init.d/$runnableScript" ]; then
    log "==> Running the start script $runnableScript ..."
    /opt/init.d/$runnableScript
else
    log "==> There is no start script to run."
fi

# Done.
    