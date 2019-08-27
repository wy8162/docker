# This is a Docker image for Oracle Linux 6.5.

It's built from CentOS. See CentOS_2_OracleLinux.txt for details.

ol6:java6 - Docker image derived from ol6. It has Java 1.6 installed under /opt. Use /opt/jdk1*/java_env.sh for environment setting.

- ol6:bare      bare Oracle Linux image
- ol6:java      built with DockerImages/java/Dockerfile.
                ol6:java7. See the detailed commands below.
                Users oracle and ywang are added as well. They can do sudo.
- ol6:datastore NOT USED ANY MORE.
                built with DockerImages/datastore/Dockerfile.
                It serves as data storage for all Weblogic servers and database system.
                It shares data volume /opt/app and various others (refer to datastore.sh for details.

Store Docker Images here:

    ol6bare_docker_image.tar.gz
    ol6java_docker_image.tar.gz