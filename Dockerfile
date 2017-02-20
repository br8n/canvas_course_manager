FROM tomcat:jre8

MAINTAINER Chris Kretler <ckretler@umich.edu>

RUN apt-get update \
 && apt-get install -y maven openjdk-8-jdk git

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

WORKDIR /tmp

# Build esbUtils, a dependency of the CCM.
RUN git clone https://github.com/tl-its-umich-edu/esbUtils \
 && cd esbUtils \
 && mvn clean install

# Build lti-utils, a dependency of the CCM.
RUN git clone https://github.com/tl-its-umich-edu/lti-utils \
 && cd lti-utils \
 && mvn clean install

# Copy CCM code to local directory for building
COPY . /tmp

# Build CCM and place the resulting war in the tomcat dir.
RUN mvn package \
 && mv ./target/canvasCourseManager.war /usr/local/tomcat/webapps

# Remove unnecessary build dependencies.
RUN apt-get remove -y maven openjdk-8-jdk git \
 && apt-get autoremove -y

WORKDIR /usr/local/tomcat/webapps

# Set Opts, including paths for the CCM properties.
ENV JAVA_OPTS="-server \
-Xmx1028m \
-Dorg.apache.jasper.compiler.Parser.STRICT_QUOTE_ESCAPING=false \
-Djava.awt.headless=true -Dcom.sun.management.jmxremote \
-Dsun.lang.ClassLoader.allowArraySyntax=true \
-Dfile.encoding=UTF-8 \
-DccmPropsPathSecure=ccmPropsPathSecure=$CATALINA_HOME/conf/ccmSecure.properties \
-DccmPropsPath=ccmPropsPath=$CATALINA_HOME/conf/ccm.properties \
"

EXPOSE 8080
EXPOSE 8009

# Launch Tomcat
CMD cp /usr/share/ccm/props/* /usr/local/tomcat/conf/; catalina.sh run
#CMD /bin/bash