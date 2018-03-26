FROM registry.centos.org/centos/centos:7

ARG VERSION=1.0-SNAPSHOT

ENV JAVA_HOME /etc/alternatives/jre
ENV CHE_STARTER_HOME /opt/che-starter

## Default ENV variable values
ENV OSO_ADDRESS tsrv.devshift.net:8443
ENV OSO_DOMAIN_NAME tsrv.devshift.net
ENV KUBERNETES_CERTS_CA_FILE /opt/che-starter/tsrv.devshift.net.cer

# took off yum -y update command from here, for pipeline-scanner to report updates
RUN yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel git && \
    yum clean all

WORKDIR $CHE_STARTER_HOME

RUN git clone https://github.com/almighty/InstallCert.git && \
     javac $CHE_STARTER_HOME/InstallCert/InstallCert.java

RUN chown -R 1000:0 ${CHE_STARTER_HOME} && chmod -R ug+rw ${CHE_STARTER_HOME}

ADD docker-entrypoint.sh $CHE_STARTER_HOME

VOLUME /tmp

# commented out following ADD command as it was failing
# ADD target/che-starter-$VERSION.jar $CHE_STARTER_HOME/app.jar

EXPOSE 10000

# ===========================================================================
# Make image prone for reporting issues via scanner
# add RUN label in image to generate report for container-capabilities-scanner
LABEL RUN='docker run --privileged -d $IMAGE' \
      git-url='https://github.com/samuzzal-choudhury/che-starter' \
      git-sha='5a835617078aa4873d585e42179a79b2e43d59d3' \
      email-ids='samuzzal@redhat.com'

# touch /usr/bin/yum inside container image to modify the file time (mtime)
# this will report issue via $rpm -V yum
RUN touch /usr/bin/yum

# Install pip and an older version of pip package so that
# misc-package update scanner can report outdated pip packages
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum -y install python-pip && yum clean all
RUN pip install django==1.11.2
# =============================================================================

ENTRYPOINT ['/opt/che-starter/docker-entrypoint.sh']
