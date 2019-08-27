#!/bin/sh
# Yang Wang

NO_ARGS=0
E_OPTERROR=65

Usage() {
		echo ""
        echo "Usage:"
        echo "wls.sh containerName"
        echo "Container name will also be used as host name. Docker image should be wlsadm"
		echo ""
}

if [[ $# != 1 ]]; then
		Usage
        exit $E_OPTERROR
fi

echo ""
echo "
--------------------------------------------------------------------------
This script will do the following:
1. Check if Docker image "ol6:java" exists.
2. If no Docker image "ol6:java", it'll import one from DockerImages
3. Start a Weblogic server container with container name as host name
4. Weblogic default password is 'password1'
5. Two users will be created: oracle and ywang, all with password marlo12
6. All these users are sudoer
7. OpenSSH will be installed and X11 is not installed

Volumes mapped:
    /opt/app from datastore - for Oracle database installation
    /vagrant                - for various tools including software packages
    /opt/init.d             - installation scripts
    /etc/supervisor/conf.d  - scripts for supervisord (NOT USED)
    /opt/log                - for log information
--------------------------------------------------------------------------
"

# wlsimg=$(docker images ol6:java | tail -1 | cut -d' ' -f1)
r=$(docker images | grep -E "ol6")

if [[ ! $r = *java* ]]; then
    echo "==> Importing Docker image ol6:java ..."

    # Import ol6:java image
    if [ -d ./DockerImages ]; then
        gzip -c -d ./DockerImages/ol6dev_docker_image.tar.gz | docker load
        id=$( docker images | sed -n 2p | awk '{ print $3 }')
        docker tag $id ol6:java
    else
        echo "==> Failed to import Docker image ol6:java. Make sure dir DockerImages exists under the current dir."
        exit 1
    fi
    
    r=$(docker images | grep -E "ol6")
    if [[ ! $r = *dev* ]]; then
        echo "==> Failed to import Docker image ol6:java. Make sure run this dir DockerImages is under the current dir."
        exit 1
    fi
fi

containName=$1
imageMame="ol6:java"

existingContainers=$(docker ps -a)

if [[ $existingContainers == *$containName* ]]
then
  echo "Deleting existing container $1"
  docker rm -v $containName
fi

docker run \
 -p 2211:22 \
 -p 7001:7001 \
 -p 7002:7002 \
 -p 5556:5556 \
 --name $containName \
 --hostname $containName \
 -v /vagrant:/opt/vagrant:ro \
 --volumes-from datastore \
 -v /vagrant/DataVol/logs/wlsadm:/opt/log \
 -v /vagrant/init.d:/opt/init.d:ro \
 -e PS1="[\u@\h \W]\$" \
 -it $imageMame /bin/bash

 # --link oracle11gr2:oracle11gr2 \