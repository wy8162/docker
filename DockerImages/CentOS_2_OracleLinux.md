Build Oracle Linux 6.5 Image for Docker and Convert CentOS to Oracle Linux
==========================================================================

## References
1. Switch CentOS to Oracle Linux: https://linux.oracle.com/switch/centos/
2. Create Docker image for Oracle Linux: https://blogs.oracle.com/wim/entry/oracle_linux_6_5_and
3. Set up Oracle Linux repositories: http://public-yum.oracle.com

## Convert CentOS 6.5 to Oracle Linux 6.5

1. Start Docker with image "centos:centos6"
   docker run -it centos:centos6 /bin/bash
   
2. Update Centos 6.5
   yum -y update
   
3. Add Oracle repositories
   cd /etc/yum.repos.d
   wget http://public-yum.oracle.com/public-yum-ol6.repo

4. Download key
   wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol6 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
   
5. Edit Oracle pubic repository "public-yum-ol6.repo"
   5.1 Enable the two UEK and UEKR3 near the bottom
   5.2 Edit CentOS libselinux.repo to use baseurl from "public-yum-ol6.repo". This is needed. Otherwise, will get errors like "cannot find baseurl of libselinux".
   
6. Download "centos2ol.sh" to, say, /tmp
   curl -O https://linux.oracle.com/switch/centos2ol.sh
   
7. Run the tool
   sh centos2ol.sh

After a while, the CentOS 6.5 will be converted to Oracle Linux 6.5.

To confirm that:
1. cat /etc/oracle_release
2. Files "/etc/yum.repos.d" are only for Orace Linux.

## Build Oracle Linux 6.5 Image for Docker

1. Start Vagrant with the box below
  config.vm.box     = "oraclelinux6.5"
  config.vm.box_url = "https://storage.us2.oraclecloud.com/v1/istoilis-istoilis/vagrant/oel65-64.box"
  
2. Install febootstrap
   sudo yum -y install febootstrap
  
3. Create docker image file
   cd /tmp
   
   sudo febootstrap -i bash -i coreutils -i tar -i bzip2 -i gzip -i vim-minimal -i wget -i patch -i diffutils -i iproute -i yum ol6 ol6 http://public-yum.oracle.com/repo/OracleLinux/OL6/latest/x86_64

   Note that the URL is needed for febootstrap to locate a "repomd.xml" file this way:
      http://public-yum.oracle.com/repo/OracleLinux/OL6/latest/x86_64/repodata/repomd.xml

   This will create a directory "/tmp/ol6".

4. Build Docker Image
   - touch ol6/etc/resolv.conf
   - touch ol6/sbin/init
   - tar it up and import it
     tar --numeric-owner -jcpf ol6.tar.gz -C ol6 .
   - cat ol6.tar.gz | docker import - ol6
   
   This will create a docker image "ol6".
   
5. Verify and use it
   - docker images
   - docker run ol6 -it /bin/bash
   
6. Save a copy of the image to local
   - docker save ol6 > ol6.tar
   
   The ol6.tar is the local docker image.
   
7. Use the docker image
   - docker load --input ol6.tar
   
## Sample File "repomd.xml"

   *http://public-yum.oracle.com/repo/OracleLinux/OL6/latest/x86_64/repodata/repomd.xml*

    <repomd xmlns="http://linux.duke.edu/metadata/repo">
        <data type="other">
            <location href="repodata/other.xml.gz"/>
            <checksum type="sha">183df522a800d353289c6f0362bcb8df2b9ab79d</checksum>
            <timestamp>1408025308</timestamp>
            <open-checksum type="sha">1cc9b46e6b03538083bc20a742caf5eba49e4325</open-checksum>
        </data>
        <data type="filelists">
            <location href="repodata/filelists.xml.gz"/>
            <checksum type="sha">24285d6513c3bcd91250f8a847b6470e3608d780</checksum>
            <timestamp>1408025306</timestamp>
            <open-checksum type="sha">7135f05078b4b3cdb084e36be59b180f11fd0e92</open-checksum>
        </data>
        <data type="primary">
            <location href="repodata/primary.xml.gz"/>
            <checksum type="sha">a87305d832e30422c2a24b1de6b8db3d7b634e1c</checksum>
            <timestamp>1408025306</timestamp>
            <open-checksum type="sha">2b2da11b1f7205375407120d2570e850ab8c6eea</open-checksum>
        </data>
        <data type="group">
            <location href="repodata/comps.xml"/>
            <checksum type="sha">08ec74da7552f56814bc7f94d60e6d1c3d8d9ff9</checksum>
            <timestamp>1340553361</timestamp>
        </data>
        <data type="updateinfo">
            <location href="repodata/updateinfo.xml.gz"/>
            <checksum type="sha">2eff7d7bf73c6dfe9027a0248ddebe09a7e9a43a</checksum>
            <timestamp>1408025341</timestamp>
            <open-checksum type="sha">7738886a080e12fac45765610f82b0ae52cb9992</open-checksum>
        </data>
    </repomd>

## Set up SSH in Docker Container
Simply installing packages openssh-server and openssh-clients in Ubuntu based images will get sshd up and running without any problem. But this is not enough for CentOS, Oracle Linux based containers.

1. Install openssh-server and openssh-clients
   yum -y install openssh-server openssh-clients
   
2. mkdir /var/run/sshd
   chmod -rx /var/run/sshd

3. Edit /etc/ssh/sshd_config and change "UsePAM yes" to "UsePAM no" and change PermitRootLogin to no.

4. Start sshd
   service sshd start
   chkconfig sshd on
   
5. The way to set it up in Docker file

    RUN echo 'root:secret' | chpasswd
    RUN yum install -y openssh-server
    RUN mkdir -p /var/run/sshd ; chmod -rx /var/run/sshd
    # http://stackoverflow.com/questions/2419412/ssh-connection-stop-at-debug1-ssh2-msg-kexinit-sent
    RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
    # Bad security, add a user and sudo instead!
    RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
    
    # The following is not needed. See the section "Troubleshooting SU and SSH Problems" below. //Yang Wang
    # http://stackoverflow.com/questions/18173889/cannot-access-centos-sshd-on-docker
    # RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
    # RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

## Troubleshooting SU and SSH Problems

1. yum -y install rsyslog
2. Change /etc/rsyslog.conf
    # Log anything (except mail) of level info or higher.
    # Don't log private authentication messages!
    *.info;mail.none;authpriv.none;cron.none                /var/log/messages

    # The authpriv file has restricted access.
    authpriv.*    
                                          /var/log/secure
3. Change /etc/ssh/sshd_config
    # Logging
    # obsoletes QuietMode and FascistLogging
    #SyslogFacility AUTH
    SyslogFacility AUTHPRIV
    LogLevel DEBUG

4. service rsyslog restart
   service sshd restart

5. "Coud not open session"
    When the nofile is set to unlimited in /etc/security/limits.conf file the user cannot login:

    user  soft nofile 1024
    user  hard nofile unlimited

    # su - user
    could not open session
    

In Docker containers, CentOS and Oracle Linux, after installation of openssh and/or oracle-rdbms-server-11gR2-preinstall.x86_64, this will cause the following problem:

1. "su - oracle" will get "can not open session" problem
2. "ssh oracle@localhost" will get "connection closed by localhost"

The root causes:
1. The pam_limit setup in /etc/pam.d/system-auth
   session     required      pam_limits.so
2. The pam_limit setup in /etc/pam.d/password-auth
   session     required      pam_limits.so
3. The nologin and pam_loginuid setups in /etc/pam.d/sshd
account    required     pam_nologin.so
...
session    required     pam_loginuid.so
The solution is to comment out all these lines.

There is a known issue about loginuid:

http://gaijin-nippon.blogspot.se/2013/07/audit-on-lxc-host.html

### How to Investigate It

1. Install syslog or rsyslog
2. Start the syslog
   service start rsyslog
3. Change log levels in /etc/ssh/sshd_config

PAM related security logs are stored in /var/log/secure.

