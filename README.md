*Yang Wang, 8/15/2014*

# Provisioning servers
====================

The plan is to create a test environment where:

1. The virtual machine, or the dockerhost, will be created by Vagrant plus VirtualBox. The dockerhost will have IP address 192.168.56.2. The host computer will have 192.168.56.1, which is the host-only interface.
2. Docker will use the image "ol6" under DockerImage to create docker containers. This image is an Oracle Linux 6.5 converted from CentOS 6.5.
3. One Docker container will run Oracle Database 11g R2.
4. Three Docker containers will run Oracle Weblogic 12c, supporting cluster.

## Vagrant Preparations
Before run Vagrant, make sure the Vagrant plugins are installed as below:

**vagrant plugin install vagrant-vbguest**

**vagrant plugin install vagrant-omnibus**

Vagrant's home directory, the current directory running vagrant command, will be mapped to dockerhost's /vagrant.

And this /vagrant will then be mapped to docker container's /vagrant.

### Volumes and Mappings
See the docker start scripts for details.

DockerHost      |   Docker Container
----------------|-------------------
/vagrant        | /opt/vagrant
                | /opt 

### Software Needed
The meeded software should be placed under vagrant/software:

    JDK
    - jdk-7u67-linux-x64.gz

    weblogic 12.12.0.0
    - wls_121200.jar

    database 11gR2
    - linux.x64_11gR2_database_1of2.zip
    - linux.x64_11gR2_database_2of2.zip

## Starting Server dockerhost
This is the server started by Vagrant with IP address "192.168.56.2". It has Docker installed automatically.

    vagrant up
    vagrant ssh
    or
    ssh -p 2200 vagrant@localhost
    
    After that, import the Docker image as below:
    
    docker load --input /vagrant/DockerImages/ol6_docker_image.tar
    
    This will create an image "ol6", which is an Oracle Linux 6.5, converted from CentOS 6.5.

## How to Start Containers
All containers, except the datastore, must map init.d to /opt/init.d. Script /opt/init.d/startd.sh should be
the command to run.

This command will find a script named with the hostname. I.e., for example, for oracle11gr2, startd.sh will find
a script named /opt/init.d/oracle11gr2.run.sh and run it.

So, oracle11gr2 will use this script to check if Oracle 11g R2 has been installed. If not, then install it. And
then start the database service. It will continue monitoring the service and writes information to /opt/log
directory.
    
## datastore
This is the container which provides data volumes for all the other containers. I.E.:

    - /vagrant/DataVol/applications:/opt/app for application installations for Weblogic ONLY.
    - /vagrant/DataVol/wlsadm:/opt/wlsadm 
    - /vagrant/DataVol/wlsms0:/opt/wlsms0 
    - /vagrant/DataVol/wlsms1:/opt/wlsms1 
    - /vagrant/DataVol/wlsms2:/opt/wlsms2 
    - /vagrant/DataVol/logs:/opt/log        for log files
    - /development:/development             for all development projects
    
This container must be the first one to be started.
    
## oracle11gr2
This is to install and start Oracle database 11g R2 in a Docker container.

The Docker container is based on image ol6. A bash shell will be started. The container
name is oracle11gr2. If there exists container oracle11gr2, then it'll delete it and start a new one.
So this is somewhat dangerous because there might be existing data in the existing container.

To start the container:

    ./oracle11gr2.sh

Details of the container:
1. Container name: oracle11gr2
2. Host name:      oracle11gr2
3. Exposed ports:  2201 for SSHD and 1521 for Oracle

Command "docker-enter" can also be used to enter a contaner. See "https://github.com/jpetazzo/nsenter" for details.

    Note that Oracle Database installation can not share data volumes from datastore. It has to use its own volume. See the oracle11gr2.sh for details. The reason why we need to use volume is because Docker containers have limited disk space which is not enough to accommodate the huge installation of Oracle 11g R2.

    Oracle Database cannot use the data volume from another container (i.e. datastore) to install Oracle Database. Otherwise many binary files including lsnrctl will have ZERO BYTES.

### Start Oracle 11g R2
The Oracle data base needs to be installed first before it can be used. Here are the steps:

1. Review oracle_constants.sh and modify it if necessary.
2. cd /opt/vagrant/ora11gr2
3. ./installoracle11gr2.sh
4. service oracle start
5. After using the server and need to stop the container, shut down the database first:
    service oracle stop

There are two ways to do it:

### Start Oracle 11g R2 - Method 1
1. Run "oracle11gr2.sh". This will start a bash shell.
2. Run /vagrant/ora11gr2/installoracle11gr2.sh, which will do the silent installation.
   - check and install sshd. X11 forwarding will be enabled.
   - add various groups
   - add users including oracle and ywang
   - create directory structures (see the script for details)
   - install Oracle Pre-Install package, which will take care of kernel parameters and dependencies.
     Some packages will be reported as missing but it's ok because newer versions are installed already.
     Only exception is pdksh which is fine too because ksh installed will take care of it.
3. The various response files are located under /opt/vagrant/ora11gr2.

### Use the Oracle Server
1. Use Oracle database
   - Server: 192.168.56.2
   - Port:   1521
   - SID:    develop
   - Password for all: password1
   
2. Login to the server
    - "ssh -Y -p 2201 oracle@192.168.56.2" if X11 is to be used. Otherwise, do not use "-Y"

## Weblogic 12c Servers
Weblogic server 12c. This is a Docker container build by wls12c/Dockerfile.

### wlsvol - container sharing volumes

- /opt/app : used for Weblogic Admin Server to install Weblogic software

### wlsadm - container for Weblogic Server
This will be the Admin Weblogic server with Admin Server and Managed Server 0.

A domain will be created: "dovetail".

### wlsms1,wlsms2

These are Weblogic managed servers under domain "dovetail".

## Users
System  | Username      |          Groups       | Password  | SUDOER    | SERVER
--------|---------------|-----------------------|-----------|-----------|-----------------------
OS      | oracle        | oinstall, dba, wheel  | marlo12   |   yes     | oracle11gr2
OS      | vagrant       | system defaults       | vagrant   |   yes     | dockerhost
OS      | root          | system defaults       | vagrant   |   N/A     | All
OS      | ywang         | users, wheel          | marlo12   |   yes     | All except dockerhost
Oracle  | db sys        | N/A                   | password1 |   N/A     | oracle11gr2
WebLogic| weblogic      | N/A                   | password1 |   N/A     | All WLS nodes

## Port Number Mappings
Application | Server     | Local Host | dockerhost | Port In Container| Description
------------|------------|------------|------------|------------------|-------------------------------------
SSH         | Dockerost  | 22         | 2200       |                  | SSH in general. Accessible from host
Oracle      | oracle11gr2| N/A        | 1521       | 1521             | Oracle 11g R2
            | oracle11gr2| N/A        | 2201       | 22               | 
Weblogic    | wlsadm     | N/A        | 7001       | 7001             | Admin Server + wlsms0 - managed server 0
            | wlsadm     | N/A        | 7002       | 7002             | 
            | wlsadm     | N/A        | 5556       | 5556             | 
            | wlsadm     | N/A        | 2211       | 22               | SSHD in wlsadm     . NOT USED.
Weblogic    | wlsms1     | N/A        | 7021       | 7021             | Managed server
            | wlsms1     | N/A        | 7022       | 7022             | 
            | wlsms1     | N/A        | 5526       | 5526             | 
            | wlsms1     | N/A        | 2212       | 22               | SSHD in wlsms1     . NOT USED.
Weblogic    | wlsms2     | N/A        | 7031       | 7031             | Managed server
            | wlsms2     | N/A        | 7032       | 7032             | 
            | wlsms2     | N/A        | 5536       | 5536             | 
            | wlsms2     | N/A        | 2213       | 22               | SSHD in wlsms2     . NOT USED.

Note that all the ports may have local applications (Desktop Windows, etc). Ports exposed to dockerhost by docker containers are accessible through 192.168.56.2, the dockerhost.

So, for example, to access 7001 in a docker container (Weblogic), use "192.168.56.2:7001".

See Vagrantfile for detailed configuration.

        {
          ":host": 2200,
          ":guest": 22,
          ":id": "ssh"
        },
        {
          ":host": 1521,
          ":guest": 1521,
          ":id": "oracledb"
        },
        {
          ":host": 7001,
          ":guest": 7001,
          ":id": "wls-listen"
        },
        {
          ":host": 5556,
          ":guest": 5556,
          ":id": "wls-nm"
        }
