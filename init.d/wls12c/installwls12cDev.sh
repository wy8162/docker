#!/bin/bash
#
# Yang Wang
#

ORACLE_U_USER=oracle
WLS_SW_DIR=/opt/init.d/software
WLS_CFG_DIR=/opt/init.d/wls12c

cd /opt/app

if [ ! -d /opt/app/oracle ]; then
    #su - $ORACLE_U_USER -c "
        mkdir -p /opt/app/oracle; \
        mkdir -p /opt/app/oracle/.inventory; \
        chown -R oracle:oracle /opt/app/oracle
        #"
fi

pushd /opt/app/oracle >/dev/null 2>&1

# Unzip the Weblogic into /opt/app/oracle
if [ ! -d /opt/app/oracle/wls12120 ]; then
    su - $ORACLE_U_USER -c "
        cd /opt/app/oracle
        cp $WLS_SW_DIR/wls1212_dev.zip .; \
        unzip wls1212_dev.zip; \
        rm wls1212_dev.zip"
fi

export MW_HOME=/opt/app/oracle/wls12120

if ! grep "JAVA_HOME" /home/oracle/.bash_profile >/dev/null 2>&1; then
    echo "==> Set up user oracle Java environment"
    su - $ORACLE_U_USER -c "cat /opt/jdk1.7.0_65/java_env.sh >> ~/.bash_profile"
fi

# Configure Weblogic
su - $ORACLE_U_USER -c "$MW_HOME/configure.sh -silent"

su - $ORACLE_U_USER -c "/opt/app/oracle/wls12120/wlserver/common/bin/wlst.sh -skipWLSModuleScanning $WLS_CFG_DIR/create-wls-domain-Dev.py"

if ! grep "ORACLE_BASE" /home/oracle/.bash_profile >/dev/null 2>&1; then
    echo "==> Set up user oracle environment profile"
    su - $ORACLE_U_USER -c "cat $WLS_CFG_DIR/wls12cDev_env.sh >> ~/.bash_profile"
fi

popd >/dev/null 2>&1

echo "
To start Node Manager: /home/oracle/wls/mydomain/bin/startNodeManager.sh
To start Weblogic:     /home/oracle/wls/mydomain/startWebLogic.sh
"
