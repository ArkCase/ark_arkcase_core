FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base:latest

###########################################################################################################
#
# How to build:
# export SSHPASS=<password for ssh>
# docker build --build-arg SSHPASS=$SSHPASS -t 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_arkcase_core:latest .
# docker push 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_arkcase_core:latest
#
# How to run: (Docker)
# 
# docker run --name ark_arkcase_core -d 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_arkcase_core:latest sleep infinity
# docker exec -it ark_arkcase_core /bin/bash
# docker stop ark_arkcase_core
# docker rm ark_arkcase_core
#
# How to run: (Kubernetes)
#
# kubectl create -f pod_ark_arkcase_core.yaml
# kubectl exec -it pod/arkcase -- bash
# tomcat/bin/startup.sh
#
# kubectl --namespace default port-forward arkcase 8080:8080  --address='0.0.0.0'
# http://iad032-1san01.appdev.armedia.com:8080/
# kubectl delete -f pod_ark_arkcase_core.yaml
#
###########################################################################################################

RUN yum -y install java-1.8.0-openjdk
ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0-openjdk

ENV BUILD_SERVER=iad032-1san01.appdev.armedia.com

LABEL ORG="ArkCase LLC" \
      VERSION="1.0" \
      IMAGE_SOURCE=https://github.com/ArkCase/ark_arkcase_core \
      MAINTAINER="ArkCase LLC"

ARG ARKCASE_VERSION=2021.03.19
ARG TOMCAT_VERSION=9.0.50 
ARG TOMCAT_MAJOR_VERSION=9
ARG SYMMETRIC_KEY=9999999999999999999999
ARG resource_path=artifacts
ARG MARIADB_CONNECTOR_VERSION=2.2.5

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

#################
# Build Arkcase
#################
ENV NODE_ENV="production" \
    ARKCASE_APP="/app/arkcase" \
    TMP=/app/arkcase/tmp \
    TEMP=/app/arkcase/tmp \
    PATH=$PATH:/app/tomcat/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin\
    SSL_CERT=/etc/tls/crt/arkcase-server.crt \
    SSL_KEY=/etc/tls/private/arkcase-server.pem
WORKDIR /app
COPY ${resource_path}/server.xml \
    ${resource_path}/logging.properties \
    ${resource_path}/arkcase-server.crt \
    ${resource_path}/arkcase-server.pem ./


RUN curl https://project.armedia.com/nexus/repository/arkcase/com/armedia/acm/acm-standard-applications/arkcase/${ARKCASE_VERSION}/arkcase-${ARKCASE_VERSION}.war -o /app/arkcase-${ARKCASE_VERSION}.war


# ADD yarn repo and nodejs package
ADD https://dl.yarnpkg.com/rpm/yarn.repo /etc/yum.repos.d/yarn.repo
ADD https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz /app
#  \
RUN yum -y update && \
    useradd  tomcat --system --user-group -d /app/tmp/ && \
    mkdir -p ${ARKCASE_APP}/data/arkcase-home && \
    mkdir -p ${ARKCASE_APP}/common && \
    mkdir -p /etc/tls/private && \
    mkdir -p /etc/tls/crt && \
    yum --assumeyes update && \
    # Nodejs prerequisites to install native-addons from npm
    yum install --assumeyes gcc gcc-c++ make openssl wget zip unzip 
RUN yum install --assumeyes nodejs 
RUN npm install -g yarn 

    #unpack tomcat tar to tomcat directory
RUN tar -xf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    mv apache-tomcat-${TOMCAT_VERSION} tomcat && \
    rm apache-tomcat-${TOMCAT_VERSION}.tar.gz &&\
    # Removal of default/unwanted Applications
    rm -rf tomcat/webapps/* tomcat/temp/* tomcat/bin/*.bat && \
    mv server.xml logging.properties tomcat/conf/ && \
    mkdir -p /tomcat/logs &&\
    mv arkcase-${ARKCASE_VERSION}.war  ./tomcat/webapps/arkcase.war && \
    mkdir -p /app/tmp/.arkcase && \
    chown -R tomcat:tomcat /app && \
    chmod u+x tomcat/bin/*.sh &&\
    # Add default SSL Keys
    mv /app/arkcase-server.crt  /etc/tls/crt/arkcase-server.crt &&\
    mv /app/arkcase-server.pem /etc/tls/private/arkcase-server.pem &&\
    chmod 644 /etc/tls/crt/* &&\
    chmod 666 /etc/pki/ca-trust/extracted/java/cacerts &&\
    # Encrypt Symmentric Key
    echo ${SYMMETRIC_KEY} > ${ARKCASE_APP}/common/symmetricKey.txt &&\
    openssl x509 -pubkey -noout -in ${SSL_CERT} -noout > ${ARKCASE_APP}/common/arkcase-server.pub &&\
    openssl rsautl -encrypt -pubin -inkey ${ARKCASE_APP}/common/arkcase-server.pub -in ${ARKCASE_APP}/common/symmetricKey.txt -out ${ARKCASE_APP}/common/symmetricKey.encrypted &&\
    rm ${ARKCASE_APP}/common/symmetricKey.txt &&\
    # Remove unwanted package
    yum clean all
    
RUN yum -y install epel-release 
RUN yum install -y tesseract tesseract-osd qpdf ImageMagick ImageMagick-devel && \
    ln -s /usr/bin/convert /usr/bin/magick &&\
    ln -s /usr/share/tesseract/tessdata/configs/pdf /usr/share/tesseract/tessdata/configs/PDF &&\
    yum update -y && yum clean all && rm -rf /tmp/*

RUN yum -y install sshpass openssh-clients

ARG SSHPASS
ENV SSHPASS=$SSHPASS
RUN sshpass -e sftp  -o StrictHostKeyChecking\=no -o UserKnownHostsFile\=/dev/null arkcase@fileshare.armedia.com:from-arkcase/arkcase-config-core-2021.03.19.zip /tmp/arkcase-config-core-2021.03.19.zip

RUN unzip /tmp/arkcase-config-core-2021.03.19.zip -d /app/tmp/.arkcase  &&\
    chown -R tomcat:tomcat /app/tmp

USER tomcat

EXPOSE 8005

CMD ["catalina.sh", "run"]
