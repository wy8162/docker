#!/bin/sh
# Yang Wang

function loadDockerImage {
    img=$1

    r=$(docker images | grep -E "ol6")

    if [[ ! $r = *${img}* ]]; then
        echo "==> Importing Docker image ol6:${img} ..."

        if [ ! -e "./DockerImages/ol6${img}_docker_image.tar.gz" ]; then
            echo "==> ./DockerImages/ol6${img}_docker_image.tar.gz does not exist. Skip importing ol6:${img}"
            return 0
        fi
        
        # Import ol6:${img} image
        if [ -d ./DockerImages ]; then
            gzip -c -d "./DockerImages/ol6${img}_docker_image.tar.gz" | docker load
            id=$( docker images | sed -n 2p | awk '{ print $3 }')
            docker tag $id ol6:${img}
        else
            echo "==> Failed to import Docker image ol6:${img}. Make sure dir DockerImages exists under the current dir."
            return 0
        fi
        
        r=$(docker images | grep -E "ol6")
        if [[ ! $r = *${img}* ]]; then
            echo "==> Failed to import Docker image ol6:${img}. Make sure run this dir DockerImages is under the current dir."
            return 0
        fi
    fi
}

echo "
-------------------------------------------------------------
This tool is to import Docker images if they don't exist yet.
-------------------------------------------------------------
"

images=(
    'bare'
    'java'
    'datastore');

for img in "${images[@]}";
do
    loadDockerImage $img
done

echo ""