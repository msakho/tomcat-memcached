FROM openshift/base-centos7

MAINTAINER Michael Morello <michael.morello@gmail.com>

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.16
ENV MAVEN_VERSION 3.5.0

EXPOSE 8080 8443

LABEL io.k8s.description="Platform for building and running Java Web applications on Tomcat 8" \
      io.k8s.display-name="Tomcat 8" \
      io.openshift.expose-services="8080:http,8443:https" \
      io.openshift.tags="builder,tomcat,tomcat8" \
      io.openshift.s2i.destination="/opt/s2i/destination"

# Install Maven and Java 8
RUN yum install -y --enablerepo=centosplus \
    tar unzip bc which lsof java-1.8.0-openjdk java-1.8.0-openjdk-devel && \
    yum clean all -y && \
    (curl -0 http://www.us.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    ln -sf /usr/local/apache-maven-$MAVEN_VERSION/bin/mvn /usr/local/bin/mvn && \
    mkdir -p /opt/s2i/destination


RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

# see https://www.apache.org/dist/tomcat/tomcat-8/KEYS
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys \
	05AB33110949707C93A279E3D3EFE6B686867BA6 \
	07E48665A34DCAFAE522E5E6266191C37C037D42 \
	47309207D818FFD8DCD3F83F1931D684307A10A5 \
	541FBE7D8F78B25E055DDEE13C370389288584E7 \
	61B832AC2F1C5A90F0F9B00A1C506407564C17A3 \
	79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED \
	9BA44C2621385CB966EBA586F72C284D731FABEE \
	A27677289986DB50844682F8ACB77FC2E86E29AC \
	A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 \
	DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 \
	F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE \
	F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

ENV TOMCAT_TGZ_URL https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

RUN set -x \
	&& curl -fSL "$TOMCAT_TGZ_URL" -o tomcat.tar.gz \
	&& curl -fSL "$TOMCAT_TGZ_URL.asc" -o tomcat.tar.gz.asc \
	&& gpg --verify tomcat.tar.gz.asc \
	&& tar -xvf tomcat.tar.gz --strip-components=1 \
	&& rm bin/*.bat \
	&& rm tomcat.tar.gz* \
        && rm -rf /usr/local/tomcat/webapps/examples \
        && rm -rf /usr/local/tomcat/webapps/docs \
        && rm -rf /usr/local/tomcat/webapps/manager \
        && rm -rf /usr/local/tomcat/webapps/host-manager \
        && rm -rf /usr/local/tomcat/webapps/ROOT

ENV CATALINA_PID /usr/local/tomcat/pid

COPY oc /usr/bin/oc
RUN chown -R 1001:0 /usr/local/tomcat && \
    chmod -R ug+rw /usr/local/tomcat && \
    chmod  ug+rwx /usr/local/tomcat/conf && \
    chmod -R g+rw /opt/s2i/destination && \
    chmod g+rw /usr/bin/oc

ENV TOMCAT_HOME /usr/local/tomcat
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk
ENV TZ Europe/Paris

#Memcache Configuraiton
COPY tomcat/lib/*.jar  $TOMCAT_HOME/lib/
COPY tomcat/conf/context.xml   $TOMCAT_HOME/conf/
COPY tomcat/conf/logging.properties  $TOMCAT_HOME/conf/
COPY tomcat/conf/catalina.sh  $TOMCAT_HOME/bin/


# Add CNAMTS CA
COPY ac_cnamts_racine.crt /etc/pki/ca-trust/source/anchors/ac_cnamts_racine.crt
COPY ac_cnamts_services.crt /etc/pki/ca-trust/source/anchors/ac_cnamts_services.crt
RUN /usr/bin/update-ca-trust extract && \
    keytool -import -trustcacerts -file /etc/pki/ca-trust/source/anchors/ac_cnamts_racine.crt -alias CNAMTS_RACINE -noprompt -storepass changeit && \
    keytool -import -trustcacerts -file /etc/pki/ca-trust/source/anchors/ac_cnamts_services.crt -alias CNAMTS_SERVICE -noprompt -storepass changeit

# AccessMaster
#COPY AccessMaster/usr /usr

# Copy the S2I scripts from the specific language image to $STI_SCRIPTS_PATH
COPY ./s2i/bin/ $STI_SCRIPTS_PATH

USER 1001
CMD $STI_SCRIPTS_PATH/usage
#CMD ["catalina.sh", "run"]
