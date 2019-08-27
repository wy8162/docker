#!/bin/bash
#
# Yang Wang
#
# Usage: This tool will be run by user oracle in .bash_profile. THis is configured by wls12c/Dockerfile.
#
# See details below.
#

#--------------------------------------------------
# The following constants / environment variables
# are definined by Dockerfile
#--------------------------------------------------
ORACLE_BASE=/opt/app/oracle
ORACLE_HOME=$ORACLE_BASE/wls12120
MW_HOME=$ORACLE_HOME
WLS_HOME=$MW_HOME/wlserver
WL_HOME=$WLS_HOME
DOMAIN_BASE=/home/oracle/wls
DOMAIN_HOME=$DOMAIN_BASE/mydomain

TOOLS_DIR=/opt/vagrant/wls12c
WLS_SW=/opt/vagrant/software/wls1212_dev.zip

echo "
This is the script for Weblogic provisioning. It resides in /opt/run.

It will install Weblogic into /opt/app/oracle and set up environments in
user oracle accordingly.

User oracle will have default password marlo12.
"

if [ -e $WLS_HOME/common/bin/wlst.sh ]; then
    echo "==> Weblogic 12c has already been installed. We're good."
    /bin/bash
    exit 0
fi

if [[ ! -e $TOOLS_DIR/installwls12cDev.sh && \
      ! -e $TOOLS_DIR/wls12cDev_env.sh && \
      ! -e $TOOLS_DIR/create-wls-domain-Dev.py ]]; then
    echo "==> Weblogic install tools under /opt/vagrant/wls12c do not exist. Please correct and do it again."
    exit 0
fi

if [[ ! -e $WLS_SW ]]; then
    echo "==> Weblogic software $WLS_SW do not exist. Please correct it and do it again."
    exit 0
fi

pushd $TOOLS_DIR >/dev/null 2>&1

./installwls12cDev.sh

popd >/dev/null 2>&1

echo "==> Done with provisioning Weblogic."

/bin/bash