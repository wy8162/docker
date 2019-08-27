#!/bin/sh
# This script is based on "http://stackoverflow.com/questions/16296753/can-you-run-gui-apps-in-a-docker".
# A convenient script used to start Docker containers
NO_ARGS=0
E_OPTERROR=65

Usage() {
		echo ""
        echo "Usage:"
        echo "rundocker.sh containerName imageName"
		echo ""
}

if [[ $# != 2 ]]; then
		Usage
        exit $E_OPTERROR
fi

containName=$1
imageMame=$2

existingContainers=$(docker ps -a)

if [[ $existingContainers == *$containName* ]]
then
  echo "Deleting existing container $1"
  docker rm -v $containName
fi

echo "Note: --privileged has been used because Oracle needs to change kernel parameters"
docker run \
 -p 2201:22 \
 -p 1521:1521 \
 -p 7001:7001 \
 -p 5556:5556 \
 --privileged \
 --name $containName \
 --hostname $containName \
 -v /opt \
 -v /vagrant:/opt/vagrant:ro \
 -e XAUTHORITY=/dockerhost/.Xauthority \
 -it $imageMame /bin/bash

 #-e DISPLAY=$(echo $DISPLAY | sed "s/^.*:/$(hostname -i):/") \