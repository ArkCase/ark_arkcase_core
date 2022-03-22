FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base:latest
LABEL ORG="ArkCase LLC" \
      VERSION="1.0" \
      IMAGE_SOURCE=https://github.com/ArkCase/ark_arkcase_core \
      MAINTAINER="ArkCase LLC"

ARG ARKCASE_VERSION=2021.03-RC11
ARG TOMCAT_VERSION=9.0.50 
ARG TOMCAT_MAJOR_VERSION=9
ARG SYMMETRIC_KEY=9999999999999999999999
ARG resource_path=artifacts
ARG MARIADB_CONNECTOR_VERSION=2.2.5
#################
# Build JDK
#################

ARG JAVA_VERSION="1.8.0.322.b06-1.el7_9"

ENV JAVA_HOME=/usr/lib/jvm/java \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN yum update -y && \
    yum -y install java-1.8.0-openjdk-devel-${JAVA_VERSION} unzip && \
    $JAVA_HOME/bin/javac -version
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
    ${resource_path}/arkcase-server.pem  \
    ${resource_path}/arkcase-${ARKCASE_VERSION}.war ./ 
# ADD yarn repo and nodejs package
ADD https://dl.yarnpkg.com/rpm/yarn.repo /etc/yum.repos.d/yarn.repo
ADD https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz /app
#  \
RUN yum -y update && \
    useradd  tomcat --system --user-group -d /app/tmp/ && \
    mkdir -p ${ARKCASE_APP}/data/arkcase-home && \
    mkdir -p ${ARKCASE_APP}/common &&\
    mkdir -p /etc/tls/private &&\
    mkdir -p /etc/tls/crt &&\
    yum --assumeyes update && \
    # Nodejs prerequisites to install native-addons from npm
    yum install --assumeyes gcc g++ make openssl wget zip unzip && \
    curl –sL https://rpm.nodesource.com/setup_6.x | bash - && \
    yum install --assumeyes nodejs &&\
    npm install -g yarn 

    #unpack tomcat tar to tomcat directory
RUN tar -xf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    mv apache-tomcat-${TOMCAT_VERSION} tomcat && \
    rm apache-tomcat-${TOMCAT_VERSION}.tar.gz &&\
    # Removal of default/unwanted Applications
    rm -rf tomcat/webapps/* tomcat/temp/* tomcat/bin/*.bat && \
    mv server.xml logging.properties tomcat/conf/ && \
    mkdir -p /tomcat/logs &&\
    mv arkcase-${ARKCASE_VERSION}.war  ./tomcat/webapps/arkcase.war && \
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
    yum -y erase unzip zip wget && \
    yum clean all
    
RUN yum -y install epel-release epel-testing && \
    yum install -y tesseract tesseract-osd qpdf ImageMagick ImageMagick-devel && \
    ln -s /usr/bin/convert /usr/bin/magick &&\
    ln -s /usr/share/tesseract/tessdata/configs/pdf /usr/share/tesseract/tessdata/configs/PDF &&\
    yum update -y && yum clean all && rm -rf /tmp/*
    
USER tomcat

EXPOSE 8005

CMD ["catalina.sh", "run", "-security"]
