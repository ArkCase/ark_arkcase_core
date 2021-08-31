FROM 345280441424.dkr.ecr.ap-south-1.amazonaws.com/ark_base_java8:latest
LABEL ORG="Armedia LLC" \
      VERSION="1.0" \
      IMAGE_SOURCE=https://github.com/ArkCase/ark_arkcase_core \
      MAINTAINER="Armedia LLC"

ARG ARKCASE_VERSION=2021.02
ARG TOMCAT_VERSION=9.0.50 
ARG TOMCAT_MAJOR_VERSION=9
ARG SYMMENTRIC_KEY=9999999999999999999999
ARG resource_path=artifacts

ENV NODE_ENV="production" \
    ARKCASE_APP="/app/arkcase" \
    JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true -Duser.home=${ARKCASE_APP}/data/arkcase-home" \
    TMP=/app/arkcase/tmp \
    TEMP=/app/arkcase/tmp \
    PATH=$PATH:/app/tomcat/bin \
    SSL_CERT=/etc/tls/crt/arkcase-server.crt
WORKDIR /app
COPY ${resource_path}/server.xml \
    ${resource_path}/logging.properties \
    ${resource_path}/arkcase-server.crt ./
# ADD yarn repo and nodejs package
ADD https://dl.yarnpkg.com/rpm/yarn.repo /etc/yum.repos.d/yarn.repo
ADD https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz /app
RUN useradd --system --user-group --no-create-home tomcat && \
    mkdir -p ${ARKCASE_APP}/data/arkcase-home && \
    mkdir -p ${ARKCASE_APP}/common &&\
    mkdir -p /etc/tls/private &&\
    mkdir -p /etc/tls/crt &&\
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
    mv server.xml logging.properties tomcat/conf/ && \
    wget --directory-prefix=./tomcat/webapps/ -O arkcase.war https://github.com/ArkCase/ArkCase/releases/download/${ARKCASE_VERSION}/arkcase-${ARKCASE_VERSION}.war &&\
    chown -R tomcat:tomcat tomcat && \
    chmod u+x tomcat/bin/*.sh &&\
    # Add default SSL Keys
    mv /app/arkcase-server.crt /etc/tls/crt/arkcase-server.crt &&\
    chmod 644 /etc/tls/crt/* &&\
    # Encrypt Symmentric Key
    echo ${SYMMENTRIC_KEY} > ${ARKCASE_APP}/common/symmetricKey.txt &&\
    openssl x509 -pubkey -noout -in ${SSL_CERT} -noout > ${ARKCASE_APP}/common/arkcase-server.pub &&\
    openssl rsautl -encrypt -pubin -inkey ${ARKCASE_APP}/common/arkcase-server.pub -in ${ARKCASE_APP}/common/symmetricKey.txt -out ${ARKCASE_APP}/common/symmetricKey.encrypted &&\
    rm ${ARKCASE_APP}/common/symmetricKey.txt &&\
    # Remove unwanted package
    yum -y erase unzip zip wget && \
    yum clean all
    
USER tomcat

EXPOSE 8080

CMD ["catalina.sh", "run"]


