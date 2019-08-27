#!/bin/sh
# Yang Wang
# A convenient script used to start Docker container for Oracle 11g R2

echo ""
echo "
==>Read this first!<==

-----------------------------------------------------------------------------------------------------
This script starts a Docker container based on image ol6. A bash shell will be started. The container
name is oracle11gr2. If there exists container oracle11gr2, then it'll delete it and start a new one.
So this is somewhat dangerous because there might be existing data in the existing container.

Details of the container:
1. Container name: oracle11gr2
2. Host name:      oracle11gr2
3. Exposed ports:  2201 for SSHD and 1521 for Oracle

The Oracle data base needs to be installed first before it can be used. Here are the steps:

1. cd /opt/init.d/ora11gr2
2. ./installoracle11gr2.sh
3. service oracle start

Before you exit from this container, remember to shut down the Oracle first:

   service oracle stop
   
Cheers.
-----------------------------------------------------------------------------------------------------
"
echo ""

hname=$(hostname)
if [ ! "$hname" == "dockerhost" ]; then
   echo "Sigh...this command must be used in dockerhost. Bye"
   echo ""
   exit 0
fi

containName="oracle11gr2"
imageMame="ol6:bare"

existingContainers=$(docker ps -a)

if [[ $existingContainers == *$containName* ]]
then
  echo "Deleting existing container $1"
  docker rm -v $containName
fi

echo "Note: --privileged has been used because Oracle needs to change kernel parameters"
echo "Volumes mapped:
    /opt/app                - for Oracle database installation
    /vagrant                - for various tools including software packages
    /opt/init.d             - installation scripts
    /etc/supervisor/conf.d  - scripts for supervisord (NOT USED)
    /opt/log                - for log information
    
"
docker run -d \
 -p 2201:22 \
 -p 1521:1521 \
 --privileged \
 --name $containName \
 --hostname $containName \
 -v /opt/app \
 -v /vagrant:/opt/vagrant:ro \
 -v /vagrant/init.d:/opt/init.d:ro \
 -v /vagrant/DataVol/logs/oracle:/opt/log \
 -v /vagrant/init.d/supervisor.d/ora11gr2:/etc/supervisor/conf.d:ro \
 -e DISPLAY=oracle11gr2:10.0 \
 -e XAUTHORITY=/dockerhost/.Xauthority \
 -e PS1="[\u@\h \W]\$" \
 -it $imageMame \
 /bin/sh -c "/opt/init.d/startd.sh"

# Why /opt/app here instead of from datastore:
#
# Note that Oracle Database installation can not share data volumes from datastore. It has to use its own volume.
# See the oracle11gr2.sh for details. The reason why we need to use volume is because Docker containers have 
# limited disk space which is not enough to accommodate the huge installation of Oracle 11g R2.

# Oracle Database cannot use the data volume from another container (i.e. datastore) to install Oracle Database. 
# Otherwise many binary files including lsnrctl will have ZERO BYTES.
 
# The following should not be used. "DISPLAY=" will cause Oracle silent installer
# to fail. Don't use it unless using GUI installation.
#
# http://dbhk.wordpress.com/2010/11/25/oracle-11gr2-silent-installation-problem/
#   Checking Temp space: must be greater than 180 MB.   Actual 180764 MB    Passed
#   Checking swap space: must be greater than 150 MB.   Actual 4233 MB    Passed
#   Preparing to launch Oracle Universal Installer from /tmp/OraInstall2010-11-25_10-52-41AM. Please wait …$ Exception in thread “main” java.lang.NoClassDefFoundError
#   at java.lang.Class.forName0(Native Method)
#   ...
#   at oracle.install.ivw.db.driver.DBInstaller.main(DBInstaller.java:132)
#
#-e DISPLAY=$(echo $DISPLAY | sed "s/^.*:/$(hostname -i):/") \