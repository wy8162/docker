# Yang Wang
# Dockerfile for WebLogic 12.12.00 development edition
#

# Image ol6:bare is needed
FROM ol6:bare

MAINTAINER Yang Wang <yang.wang@myeamil.com>

VOLUME /opt/app

USER root

# Install SSH

# Prepare the Oracle Linux 6.5: install packages including X11, SSH, etc
RUN cd /etc/yum.repos.d ; \
    wget http://public-yum.oracle.com/public-yum-ol6.repo ; \
    wget http://public-yum.oracle.com/RPM-GPG-KEY-oracle-ol6 -O /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle ; \
    yum -y install openssh-server openssh-clients sudo passwd rsyslog unzip

# Configure SSH
# The following are needed because of Docker kernel bug. See CentOS_2_OracleLinux.md for details.
RUN sed -ri 's/^(session +required +pam_limits)/#\1/g' /etc/pam.d/system-auth ; \
    sed -ri 's/^(session +required +pam_limits)/#\1/g' /etc/pam.d/password-auth ; \
    sed -ri 's/^(account +required +pam_nologin)/#\1/g' /etc/pam.d/sshd ; \
    sed -ri 's/^(session +required +pam_loginuid)/#\1/g' /etc/pam.d/sshd

RUN mkdir /var/run/sshd ; \
    chmod -rx /var/run/sshd ; \
    chkconfig sshd on ; \
    chkconfig rsyslog on ; \
    service sshd start ; \
    service rsyslog start
    
# Install and setup Java 7

WORKDIR /opt

# Docker will automatically uncompress the file. So no need to uncompress it any more.
ADD jdk-7u65-linux-x64.tar.gz /opt

RUN chown -R root:root /opt/jdk1.7.0_65 ; \
    alternatives --install /usr/bin/java java /opt/jdk1.7.0_65/bin/java 1 ; \
    echo 1 | alternatives --config java ; \
    alternatives --install /usr/bin/jar jar /opt/jdk1.7.0_65/bin/jar 1 ; \
    alternatives --install /usr/bin/javac javac /opt/jdk1.7.0_65/bin/javac 1 ; \
    alternatives --set jar /opt/jdk1.7.0_65/bin/jar ; \
    alternatives --set javac /opt/jdk1.7.0_65/bin/javac ; \
    echo "# Setup JAVA environments" >> java_env.sh ; \
    echo "export JAVA_HOME=/opt/jdk1.7.0_65" >> java_env.sh ; \
    echo "export JRE_HOME=/opt/jdk1.7.0_65/jre" >> java_env.sh ; \
    echo "export PATH=$PATH:/opt/jdk1.7.0_65/bin:/opt/jdk1.7.0_65/jre/bin" >> java_env.sh ; \
    java -version

# Setup users
RUN groupadd -g 501 oracle ; \
    useradd -m -u 501 -s /bin/bash -g oracle -G wheel oracle ; \
    echo oracle:marlo12 | chpasswd ; \
    useradd -m -u 502 -g users -G wheel ywang ; \
    echo ywang:marlo12 | chpasswd ; \
    echo "oracle ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers ; \
    echo "ywang ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    
# Expose Node Manager default port, and also default http/https ports for admin console
EXPOSE 5556 7001 7002

# Add the entry point script
ADD wlsprovision.sh /opt/docker/wlsprovision.sh

ENTRYPOINT ["/opt/docker/wlsprovision.sh"]

ENV PS1 [\u@\h]\W[\A]
