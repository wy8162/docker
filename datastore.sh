#!/bin/sh
# Yang Wang

echo "
Start WLSVOL container.
"

existingContainers=$(docker ps -a)

if [[ $existingContainers == *datastore* ]]
then
  echo "Datastore exists. So no need to run it again."
  echo ""
  exit 0
fi

docker run \
    -v /vagrant/DataVol/applications:/opt/app \
    -v /vagrant/DataVol/wlsadm:/opt/wlsadm \
    -v /vagrant/DataVol/wlsms0:/opt/wlsms0 \
    -v /vagrant/DataVol/wlsms1:/opt/wlsms1 \
    -v /vagrant/DataVol/wlsms2:/opt/wlsms2 \
    -v /development:/development \
    --name datastore \
    ol6:bare echo "Datastore"
