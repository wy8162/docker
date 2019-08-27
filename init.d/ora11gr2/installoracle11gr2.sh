#!/bin/bash
#
# Script to install Oracle 11g R2
#
# Yang Wang, 08/21/2014
#
#------------------------------------------------------
# Constants
#------------------------------------------------------
source ./oracle_constants.sh

#
# The following is IMPORTANT. Otherwise, the Oracle installer will get following errors and fail to install.
# http://dbhk.wordpress.com/2010/11/25/oracle-11gr2-silent-installation-problem/
#   Checking Temp space: must be greater than 180 MB.   Actual 180764 MB    Passed
#   Checking swap space: must be greater than 150 MB.   Actual 4233 MB    Passed
#   Preparing to launch Oracle Universal Installer from /tmp/OraInstall2010-11-25_10-52-41AM. Please wait …$ Exception in thread “main” java.lang.NoClassDefFoundError
#   at java.lang.Class.forName0(Native Method)
#   ...
#   at oracle.install.ivw.db.driver.DBInstaller.main(DBInstaller.java:132)
#savedDISPLAY=$DISPLAY
#unset DISPLAY
#
# Changed to do this when install Oracle database

#------------------------------------------------------
# Functions start here
#------------------------------------------------------
function isInstalled {
  if yum list installed "$@" >/dev/null 2>&1; then
    return 0 # true
  else
    return 1 # false
  fi
}

function configureSSH {
    echo "Configuring ssh now..."
    if ! grep -E "#session +required +pam_limits" /etc/pam.d/system-auth; then
        echo "Fixing /etc/pam.d/system-auth"
        sed -ri 's/^(session +required +pam_limits)/#\1/g' /etc/pam.d/system-auth
    fi
    if ! grep -E "#session +required +pam_limits" /etc/pam.d/password-auth; then
        echo "Fixing /etc/pam.d/password-auth"
        sed -ri 's/^(session +required +pam_limits)/#\1/g' /etc/pam.d/password-auth
    fi
    if ! grep -E "#account +required +pam_nologin" /etc/pam.d/sshd; then
        echo "Fixing /etc/pam.d/sshd"
        sed -ri 's/^(account +required +pam_nologin)/#\1/g' /etc/pam.d/sshd
    fi
    if ! grep -E "#session +required +pam_loginuid" /etc/pam.d/sshd; then
        echo "Fixing /etc/pam.d/sshd"
        sed -ri 's/^(session +required +pam_loginuid)/#\1/g' /etc/pam.d/sshd
    fi
    
    # Enable X11 forwarding
    sed -ri 's/#X11Forwarding yes/X11Forwarding yes/g' /etc/ssh/sshd_config
    sed -ri 's/#X11DisplayOffset 10/X11DisplayOffset 10/g' /etc/ssh/sshd_config
    sed -ri 's/#X11UseLocalhost yes/X11UseLocalhost yes/g' /etc/ssh/sshd_config
    
    echo "X11 Forwarding is enabled. So command ssh -Y host can be used."
    
    service sshd restart
}

function installSSH {
    if [ ! -f "/etc/yum.repos.d/public-yum-ol6.repo" ];
    then
        echo "Installing Oracle Public YUM Repository"
        cd /etc/yum.repos.d
        wget http://public-yum.oracle.com/public-yum-ol6.repo
        wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol6 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
        cd
    fi
    
    if [ ! -d "/etc/ssh" ]; then
        echo "Installing openssh-server openssh-clients sudo passwd rsyslog unzip xterm..."
        yum -y install openssh-server openssh-clients sudo passwd \
               rsyslog unzip xterm xorg-x11-xauth libXtst \
               xorg-x11-fonts-base liberation-fonts xorg-x11-fonts-* \
               xterm xfonts-base ttf-liberation
               
        mkdir /var/run/sshd
        chmod -rx /var/run/sshd
        chkconfig sshd on
        chkconfig rsyslog on
        service sshd start
        service rsyslog start
    fi
    
    configureSSH
}

function addGroupAndUser {
    echo "==> Creating Oracle groups and user oracle. Default password marlo12"
    groupadd -g 501 oinstall
    groupadd -g 502 dba
    groupadd -g 503 oper
    groupadd -g 504 asmadmin
    groupadd -g 506 asmdba
    groupadd -g 505 asmoper

    useradd -u 502 -g oinstall -G dba,asmdba,oper,wheel oracle

    # Change password anyway
    echo oracle:marlo12 | chpasswd

    if ! grep "ywang" /etc/passwd; then
        /usr/sbin/useradd -m -u 501 -g users -G wheel ywang
    else
        echo "==> User ywang exists"
    fi
    # Change password anyway
    echo ywang:marlo12 | chpasswd
    
    # Add us to the SUDOERS
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo "ywang ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
}

function createDirStructureAndSetupScripts {
    if [ -e /etc/profile.d/custom.sh ]; then
        echo "==> File custom.sh exists"
    else
        # Not to add the following script because Docker container does not allow
        # changing limits. //Yang Wang
        #cp /vagrant/ora11gr2/custom.sh /etc/profile.d
        #chmod +x /etc/profile.d/custom.sh
        echo "==> Docker container does not allow changing limits. So not to add custom.sh"
    fi

    if [ ! -d $ORACLE_HOME ]; then
        mkdir -p $ORACLE_HOME
    fi
    chown -R $ORACLE_U_USER:$ORACLE_G_OINSTALL $ORACLE_DIR
    chmod -R 775 $ORACLE_DIR

    if ! grep "ORACLE_BASE" /home/oracle/.bash_profile >/dev/null 2>&1; then
        echo "==> Set up user oracle environment profile"
        cat >> /home/oracle/.bash_profile << EOF
TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR

ORACLE_HOSTNAME=$ORACLE_HOST_NAME; export ORACLE_HOSTNAME
ORACLE_UNQNAME=develop; export ORACLE_UNQNAME
ORACLE_BASE=$ORACLE_DIR/oracle; export ORACLE_BASE
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1; export ORACLE_HOME
ORACLE_SID=develop; export ORACLE_SID

PATH=/usr/sbin:$PATH; export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH

LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
EOF
    else
        echo "==> Profile /home/oracle/.bash_profile already configured"
    fi
    
   if ! grep "JAVA_HOME" /home/oracle/.bash_profile >/dev/null 2>&1; then
        echo "==> Set up user oracle Java environment profile"
        cat $JAVA_HOME/java_env.sh >> /home/oracle/.bash_profile
    fi
}

function installJava {
    if [ -d $JAVA_HOME ]; then
        echo "==> Java alrady installed under $JAVA_HOME"
        return
    fi
    
    cp $ORACLE_SW_DIR/$JAVA_SW_NAME /opt
    cd /opt
    tar xzf $JAVA_SW_NAME
    chown -R root:root $JAVA_HOME
    alternatives --install /usr/bin/java java /opt/jdk1.7.0_65/bin/java 1
    echo 1 | alternatives --config java
    alternatives --install /usr/bin/jar jar /opt/jdk1.7.0_65/bin/jar 1
    alternatives --install /usr/bin/javac javac /opt/jdk1.7.0_65/bin/javac 1
    alternatives --set jar /opt/jdk1.7.0_65/bin/jar
    alternatives --set javac /opt/jdk1.7.0_65/bin/javac
    echo "# Setup JAVA environments" >> $JAVA_HOME/java_env.sh
    echo "export JAVA_HOME=/opt/jdk1.7.0_65" >> $JAVA_HOME/java_env.sh
    echo "export JRE_HOME=/opt/jdk1.7.0_65/jre" >> $JAVA_HOME/java_env.sh
    echo "export PATH=\$PATH:/opt/jdk1.7.0_65/bin:/opt/jdk1.7.0_65/jre/bin" >> $JAVA_HOME/java_env.sh
    java -version
    rm /opt/$JAVA_SW_NAME
}

function installNeededPackagesForOracle {
# Not used because I'm using Oracle PreInstall package. Save for later usage if needed.
# Run this function if Oracle PreInstall Package does not work. //Yang Wang
	yum -y install binutils compat-db gcc gcc-c++ glibc unixODBC \
                   compat-libstdc++-33-3.2.3 elfutils-libelf-devel \
                   glibc-common libstdc++ libstdc++-devel gnome-libs make \
                   pdksh sysstat libaio libaio-devel xscreensaver openmotif21 xorg-x11-xfs \
                   usbutils urw-fonts shared-mime-info perl-libwww-perl \
                   perl-XML-Parser perl-URI perl-HTML-Tagset perl-HTML-Parser \
                   patch lvm2 intltool libIDL libart_lgpl libbonobo xterm \
                   libcap libcroco libgnomecanvas libexif libgnomecups \
                   libgnomeprint22 libsoup libwnck libxklavier
}

function prepareOracleInstallResponse {
    parameters=(
    "<%ORACLE_BASE%>:$ORACLE_BASE"
    "<%ORACLE_HOME%>:$ORACLE_HOME"
    "<%ORACLE_INVENTORY%>:$ORACLE_INVENTORY"
    "<%ORACLE_PASSWORD%>:$ORACLE_PASSWORD"
    "<%ORACLE_OPTION%>:$ORACLE_OPTION"
    "<%ORACLE_LANGUAGE%>:$ORACLE_LANGUAGE"
    "<%ORACLE_CHARSET%>:$ORACLE_CHARSET"
    "<%ORACLE_EDITION%>:$ORACLE_EDITION"
    "<%ORACLE_HOSTNAME%>:$ORACLE_HOST_NAME"
    "<%ORACLE_SID%>:$ORACLE_SID"
    "<%ORACLE_DBNAME%>:$ORACLE_DBNAME"
    "<%ORACLE_U_USER%>:$ORACLE_U_USER"
    "<%ORACLE_U_PASSWORD%>:$ORACLE_U_PASSWORD"
    "<%ORACLE_G_OINSTALL%>:$ORACLE_G_OINSTALL"
    "<%ORACLE_G_DBA%>:$ORACLE_G_DBA")

    cp $ORACLE_RSP_INSTALL $ORACLE_INSTALL_DIR/db_install.rsp

    for e in "${parameters[@]}" ; do
        KEY=${e%%:*}
        VALUE=${e#*:}
        sed -ri 's|'$KEY'|'$VALUE'|g' $ORACLE_INSTALL_DIR/db_install.rsp
    done
    
    echo "==> Database installation response file prepared: $ORACLE_INSTALL_DIR/db_install.rsp"
}

function prepareTnsnamesSqlnet {
    parameters=(
    "<%ORACLE_HOSTNAME%>:$ORACLE_HOST_NAME"
    "<%ORACLE_SID%>:$ORACLE_SID")

    cp $ORACLE_T_TNSNAMES $ORACLE_INSTALL_DIR/tnsnames.ora
    cp $ORACLE_T_SQLNET $ORACLE_INSTALL_DIR/sqlnet.ora

    for e in "${parameters[@]}" ; do
        KEY=${e%%:*}
        VALUE=${e#*:}
        sed -ri 's|'$KEY'|'$VALUE'|g' $ORACLE_INSTALL_DIR/tnsnames.ora
    done
    
    if [ -e $ORACLE_TNSNAMES ]; then
        echo "Saved $ORACLE_TNSNAMES to ${ORACLE_TNSNAMES}.backup"
        su - $ORACLE_U_USER -c "cp $ORACLE_TNSNAMES ${ORACLE_TNSNAMES}.backup"
    fi

    if [ -e $ORACLE_SQLNET ]; then
        echo "Saved $ORACLE_SQLNET to ${ORACLE_SQLNET}.backup"
        su - $ORACLE_U_USER -c "cp $ORACLE_SQLNET ${ORACLE_SQLNET}.backup"
    fi
    
    su - $ORACLE_U_USER -c "cp $ORACLE_INSTALL_DIR/tnsnames.ora $ORACLE_TNSNAMES"
    su - $ORACLE_U_USER -c "cp $ORACLE_INSTALL_DIR/sqlnet.ora $ORACLE_SQLNET"
    
    echo "==> Oracle $ORACLE_TNSNAMES and $ORACLE_SQLNET have been created."
}

function installSqlDeveloper {
    rpm -Uhv $ORACLE_SW_DIR/sqldeveloper-4.0.2.15.21-1.noarch.rpm
}


# Usage: fn=lookForOracleLogFile
# RETURN: "" = no log file
#            = log file name
#
# It waits for 50 seconds so that Oracle can have the time to write the log file
#

function lookForOracleLogFile {
    logdirs=(
        "$ORACLE_INVENTORY"
        "/tmp"
        )
        
    cnt=0
    while :
    do
        for dir in "${logdirs[@]}";
        do
            if [ -d $dir ]; then
                # Looking for log file created within last 2 minutes
                fn=$(find $dir -type f -mmin -2 -name "installActions*log")
                if [[ $fn = *installActions* ]]; then
                    echo "$fn"
                    return 0
                fi
            fi
        done
        let cnt=$cnt+1
        if (( $cnt >= 10 )); then
            return 0
        fi
        
        sleep 5
    done  
    return 1
}

function installOracleDatabaseSoftware {
    if [[ -e $ORACLE_HOME/bin/dbca && -e $ORACLE_HOME/bin/netca ]]; then
        echo "==> Oracle has already been installed."
        return 0
    fi

    swFile1="${ORACLE_SW_NAME}_1of2.zip"
    swFile2="${ORACLE_SW_NAME}_2of2.zip"

    if [[ -e $ORACLE_INSTALL_DIR/$swFile1 && -e $ORACLE_INSTALL_DIR/$swFile2 ]]; then
        echo "==> Files $swFile1 and $swFile2 exist in $ORACLE_INSTALL_DIR"
    else
        echo "==> Copying $swFile1 and $swFile2 to $ORACLE_INSTALL_DIR..."
        su - $ORACLE_U_USER -c "mkdir -p $ORACLE_INSTALL_DIR"
        su - $ORACLE_U_USER -c " \
        cp $ORACLE_SW_DIR/$swFile1 $ORACLE_INSTALL_DIR; \
        cp $ORACLE_SW_DIR/$swFile2 $ORACLE_INSTALL_DIR"       
    fi
    
    if [ ! -d $ORACLE_INSTALL_DIR/database ]; then
        echo "==> Uncompressing $swFile1 and $swFile2..."
        su - $ORACLE_U_USER -c "cd $ORACLE_INSTALL_DIR; unzip $swFile1" >/dev/null 2>&1
        su - $ORACLE_U_USER -c "cd $ORACLE_INSTALL_DIR; unzip $swFile2" >/dev/null 2>&1
    fi
    
    prepareOracleInstallResponse
    
    echo "==> Now installing the Oracle database software..."
    
    # Add the code below to wait for the installation to complete
    # This is because runInstaller will spawn a process to install and exit immediately
    su - $ORACLE_U_USER -c "cd $ORACLE_INSTALL_DIR/database; \
    $ORACLE_INSTALL_DIR/database/runInstaller \
       -silent \
       -force \
       -noconfig \
       -ignoreSysPrereqs \
       -ignorePrereq \
       -jreLoc /opt/jdk1.7.0_65/jre \
       -responseFile $ORACLE_INSTALL_DIR/db_install.rsp"

    # Wait until the background installer finishes the work - either successful or failed
    
    # Wait until a log file is ready for being checked
    sleep 15

    #LOGFILE=$(echo $ORACLE_INVENTORY/logs/$(ls -t $ORACLE_INVENTORY/logs/installAction*log | head -n 1))
    LOGFILE=$(lookForOracleLogFile)
    
    echo "==> Oracle installation log file: $LOGFILE"
    grep -q 'INFO: Shutdown Oracle Database' $LOGFILE
    while [[ $? -ne 0 ]] ; do
        sleep 2
        grep -q 'INFO: Shutdown Oracle Database' $LOGFILE
    done

    if [ -e $ORACLE_INVENTORY/orainstRoot.sh ]; then
        $ORACLE_INVENTORY/orainstRoot.sh
    fi
    if [ -e $ORACLE_HOME/root.sh ]; then
        $ORACLE_HOME/root.sh
    fi
}

function createDatabase {
    echo "==> Configuring listener..."
    su - $ORACLE_U_USER -c "netca -silent -responsefile $ORACLE_RSP_NETCA"

    echo "==> Status of the listener:"
    su - $ORACLE_U_USER -c "lsnrctl status LISTENER"
    
    echo "==> Creating database $ORACLE_SID..."
    su - $ORACLE_U_USER -c "
    dbca -silent \
        -createDatabase \
        -templateName General_Purpose.dbc \
        -gdbName $ORACLE_DBNAME \
        -sid $ORACLE_SID \
        -sysPassword $ORACLE_PASSWORD \
        -systemPassword $ORACLE_PASSWORD \
        -sysmanPassword $ORACLE_PASSWORD \
        -dbsnmpPassword $ORACLE_PASSWORD \
        -emConfiguration LOCAL \
        -datafileJarLocation $ORACLE_HOME/assistants/dbca/templates \
        -characterset $ORACLE_CHARSET \
        -obfuscatedPasswords false \
        -sampleSchema false \
        -asmSysPassword $ORACLE_PASSWORD"
    
    echo "==> Database $ORACLE_SID created. Try to test it with 'sqlplus sys@develop AS SYSDBA'"
}

function configureOracleService {
    echo "==> Installing an Oracle service. Oracle service is stopped by default."
    cp $ORACLE_SERVICE_SCRIPT /etc/init.d/oracle
    chmod +x /etc/init.d/oracle
    chkconfig --add oracle
    chkconfig oracle off
}

function isOracleFunctioning {
# Not being used yet. Saved for later reference.
    check_stat=`ps -ef|grep ${ORACLE_SID}|grep pmon|wc -l`;
    echo "$check_stat"
    oracle_num=`expr $check_stat`
    if [ $oracle_num -lt 1 ]; then
        return 1
    fi

    # Test to see if Oracle is accepting connections
    cat >> /tmp/test_sql_$ORACLE_SID.sql << EOF
      select * from v\$database;
      exit
EOF

    testresult=$(su - oracle -c "sqlplus sys/password1@developdb AS SYSDBA @/tmp/test_sql_$ORACLE_SID.sql")
    #sqlplus sys/password1@developdb AS SYSDBA @/tmp/sql.sql > /tmp/check_$ORACLE_SID.ora
    rm /tmp/test_sql_$ORACLE_SID.sql

    if [[ $testresult == *Connected* ]]; then
        return 0 # true
    else
        return 1 # false
    fi
}

#------------------------------------------------------
# Main program starts here
#------------------------------------------------------
#user=`ps -o user= -p $$ | awk "{print $1}"`
#
# Better solution: get the current user name
user=`id -nu`

if [ "$user" == "root" ]; then
    echo ""
    echo "Beginning the installation of Oracle 11g R2"
else
    echo ""
    echo "This install tool has to be executed by user root."
    echo ""
    exit 0
fi

echo ""
echo "==> Checking prerequisite environments..."
echo "==> Checking sshd, etc..."

if [ ! -d "/etc/ssh" ]; then
    echo "Installing packages openssh-server openssh-clients sudo passwd rsyslog..."
    installSSH
fi

echo "==> Installing Java $JAVA_SW_NAME..."
installJava

if [ ! -f "/etc/yum.repos.d/public-yum-ol6.repo" ];
then
    echo "Installing Oracle Public YUM Repository"
    cd /etc/yum.repos.d
    wget http://public-yum.oracle.com/public-yum-ol6.repo
    wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol6 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
    cd
fi

echo "Preparing users oracle, ywang, group oinstall, dba. User ywang and oracle will \
be able to sudo. Default password for both ywang and oracle will be marlo12. \
We do this first so that we can use our preferred user and group IDs"

addGroupAndUser

oraclePreinstall="oracle-rdbms-server-11gR2-preinstall.x86_64"

if ! isInstalled $oraclePreinstall; then
    echo "Installing $oraclePreinstall ..."
    yum -y install oracle-rdbms-server-11gR2-preinstall.x86_64
    
    # Reconfigure SSH because Oracle Preinstall will add some value to pam.d/*.
    configureSSH
else
    echo "$oraclePreinstall already installed."
fi

createDirStructureAndSetupScripts

savedDISPLAY=$DISPLAY
unset DISPLAY
installOracleDatabaseSoftware
DISPLAY=$savedDISPLAY
export DISPLAY

if [[ -e $ORACLE_HOME/bin/dbca && -e $ORACLE_HOME/bin/netca ]]; then
    createDatabase
    configureOracleService
fi

if [[ -e $ORACLE_HOME/bin/dbca && -e $ORACLE_HOME/bin/netca ]]; then
    prepareTnsnamesSqlnet
    echo "==> Oracle database has been installed successfully!"
    
    echo "==> Now shut down Oracle ..."
    su - $ORACLE_U_USER -c "$ORACLE_HOME/bin/lsnrctl stop"
    su - $ORACLE_U_USER -c "$ORACLE_HOME/bin/dbshut $ORACLE_HOME"
    su - $ORACLE_U_USER -c "$ORACLE_HOME/bin/emctl stop dbconsole"
    rm -f /var/lock/subsys/oracle >/dev/null 2>&1
    
    echo "--------------------------------------------------------------------------------------------"
    echo "IMPORTANT:"
    echo "Oracle will not be restarted automatically. So manually starting and shuting down are needed"
    echo "To start: service oracle start"
    echo "To shutdown: service oracle stop"
    echo "In case Oracle not being started correctly, check to make sure /etc/oratab has correct values"
    echo "including SID, Oracle Home Directory, and Y instead of N."
    echo "--------------------------------------------------------------------------------------------"
else
    echo "==> !!!!!Failed to install Oracle database!!!!!"
fi

echo "==> TO DO: uncomment the following line to remove $ORACLE_INSTALL_DIR"
rm -rf $ORACLE_INSTALL_DIR

#------------------------------------------------------
# End of Program
#------------------------------------------------------
echo ""
echo "--------------------------------------------------------------------------------------------"
echo "IMPORTANT:"
echo "Oracle will not be restarted automatically. So manually starting and shuting down are needed"
echo "To start: service oracle start"
echo "To shutdown: service oracle stop"
echo "In case Oracle not being started correctly, check to make sure /etc/oratab has correct values"
echo "including SID, Oracle Home Directory, and Y instead of N."
echo "--------------------------------------------------------------------------------------------"
echo ""