FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base_java8:latest
LABEL ORG="Armedia LLC" \
      VERSION="1.0" \
      IMAGE_SOURCE=https://github.com/ArkCase/ark_arkcase_core \
      MAINTAINER="Armedia LLC"

ARG ARKCASE_VERSION=2021.02
ARG TOMCAT_VERSION=9.0.50 
ARG TOMCAT_MAJOR_VERSION=9

ENV NODE_ENV="production" \
    ARKCAE_APP="/app/arkcase" \
    JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Duser.home=${ARKCAE_APP}/data/arkcase-home" \
    TMP=/app/arkase/tmp \
    TEMP=/app/arkase/tmp \
    PATH=$PATH:/app/tomcat/bin
WORKDIR /app
COPY server.xml ./
# ADD yarn repo and nodejs package
ADD https://dl.yarnpkg.com/rpm/yarn.repo /etc/yum.repos.d/yarn.repo
ADD https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz /app
RUN useradd --system --user-group --no-create-home tomcat && \
    mkdir -p ${ARKCAE_APP}/data/arkcase-home && \
    mkdir -p ${ARKCAE_APP}/common &&\
    yum --assumeyes update; \
    # Nodejs prerequisites to install native-addons from npm
    yum install --assumeyes gcc g++ make openssl wget zip unzip && \
    curl –sL https://rpm.nodesource.com/setup_6.x | bash - && \
    yum install --assumeyes nodejs && \
    #unpack tomcat tar to tomcat directory
    tar -xf apache-tomcat-${TOMCAT_VERSION}.tar.gz && \
    mv apache-tomcat-${TOMCAT_VERSION} tomcat && \
    rm apache-tomcat-${TOMCAT_VERSION}.tar.gz &&\
    # Removal of default/unwanted Applications
    rm -rf tomcat/webapps/* tomcat/temp/* tomcat/logs tomcat/bin/*.bat && \
    mv server.xml tomcat/conf/ && \
    wget --directory-prefix=./tomcat/webapps/ -O arkcase.war https://github.com/ArkCase/ArkCase/releases/download/${ARKCASE_VERSION}/arkcase-${ARKCASE_VERSION}.war &&\
    chown -R tomcat:tomcat tomcat && \
    chmod u+x tomcat/bin/*.sh 

USER tomcat

EXPOSE 8080

CMD ["catalina.sh", "run"]


