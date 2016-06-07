FROM centos:latest
MAINTAINER Damien Claveau <damien.claveau@gmail.com>

## PREREQUESITES ##
RUN yum update  -y && yum clean all
RUN yum install -y wget git unzip zip which \
 && yum install -y krb5-server krb5-libs krb5-workstation \
 && yum install -y krb5-auth-dialog pam_krb5 \
 && yum install -y openssh-server openssh-clients \
 && yum clean all

# jdk
RUN cd /tmp \
 && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u11-b12/jdk-8u11-linux-x64.rpm \
 && rpm -ivh jdk-*-linux-x64.rpm \
 && rm jdk-*-linux-x64.rpm
ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin

# jce
RUN yum install -y unzip && yum clean all \
 && cd /tmp \
 && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip \
 && unzip jce_policy-8.zip \
 && mv -f UnlimitedJCEPolicyJDK8/*.jar $JAVA_HOME/jre/lib/security/ \
 && rm -rf jce_policy-8.zip UnlimitedJCEPolicyJDK8

# play
RUN curl -O http://downloads.typesafe.com/typesafe-activator/1.3.9/typesafe-activator-1.3.9.zip \
 && unzip typesafe-activator-1.3.9.zip -d / \
 && rm typesafe-activator-1.3.9.zip \
 && chmod a+x /activator-dist-1.3.9/bin/activator
ENV PATH $PATH:/activator-dist-1.3.9/bin

## CONFIGURE ##

ENV ELEPHANT_CONF_DIR ${ELEPHANT_CONF_DIR:-/usr/dr-elephant/app-conf}

#ARG HADOOP_VERSION
ENV HADOOP_VERSION ${HADOOP_VERSION:-2.7.1}

#ARG SPARK_VERSION
ENV SPARK_VERSION ${SPARK_VERSION:-1.6.0}

#ARG HADOOP_HOME
ENV HADOOP_HOME ${HADOOP_HOME:-/usr/hdp/current/hadoop-client}

#ARG HADOOP_CONF_DIR
ENV HADOOP_CONF_DIR ${HADOOP_CONF_DIR:-/etc/hadoop/conf}

ENV PATH $HADOOP_HOME/bin:$PATH

## BUILD AND INSTALL ##

RUN git clone https://github.com/linkedin/dr-elephant.git /tmp/dr-elephant \
 && cd /tmp/dr-elephant \
 && echo "" >> ./build.sbt && echo "resolvers += \"scalaz-bintray\" at \"https://dl.bintray.com/scalaz/releases\"" >> ./build.sbt \
 && sed -i -e "s/clean\stest\scompile\sdist/clean compile dist/g"    ./compile.sh \
 && sed -i -e "s/hadoop_version=.*/hadoop_version=$HADOOP_VERSION/g" ./app-conf/compile.conf \
 && sed -i -e "s/spark_version=.*/spark_version=$SPARK_VERSION/g"    ./app-conf/compile.conf \
 && ./compile.sh ./app-conf/compile.conf \
 && unzip ./dist/dr-elephant-2.0.3-SNAPSHOT -d /usr \
 && cp -R ./app-conf /usr/dr-elephant-2.0.3-SNAPSHOT \
 && ln -s  /usr/dr-elephant-2.0.3-SNAPSHOT /usr/dr-elephant \
 && rm -Rf /tmp/dr-elephant

## CONFIGURE ##

# Linked MySql container env vars are injected
# Keytab configuration should be valued as env vars by docker run
RUN cd /usr/dr-elephant \
 && sed -i -e "s/port=.*/port=\${http_port:-8080}/g"                              ./app-conf/elephant.conf \
 && sed -i -e "s/db_url=.*/db_url\=\${MYSQL_PORT_3306_TCP_ADDR:-localhost}/g"     ./app-conf/elephant.conf \
 && sed -i -e "s/db_name=.*/db_name=\${MYSQL_ENV_MYSQL_DATABASE:-drelephant}/g"   ./app-conf/elephant.conf \
 && sed -i -e "s/db_user=.*/db_user=\${MYSQL_ENV_MYSQL_USER:-root}/g"             ./app-conf/elephant.conf \
 && sed -i -e "s/db_password=.*/db_password=\${MYSQL_ENV_MYSQL_PASSWORD:-""}/g"   ./app-conf/elephant.conf \
 && sed -i -e "s/#\skeytab_user=.*/keytab_user=\${keytab_user:-""}/g"             ./app-conf/elephant.conf \
 && sed -i -e "s/#\skeytab_location=.*/keytab_location=\${keytab_location:-""}/g" ./app-conf/elephant.conf

## RUN ##

EXPOSE 8080

VOLUME $ELEPHANT_CONF_DIR $HADOOP_HOME $HADOOP_CONF_DIR

CMD ["/usr/dr-elephant/bin/start.sh"]


# How to run ?
# docker pull mysql:latest
# docker run --name mysql-drelephant -e MYSQL_ROOT_PASSWORD=drelephant -e MYSQL_DATABASE=drelephant -e MYSQL_USER=drelephant -e 
# MYSQL_PASSWORD=drelephant -d mysql
# docker run --name drelephant --link mysql-drelephant:mysql  -i -t \
#    -e HADOOP_HOME='/usr/hdp/current/hadoop-client' \
#    -e HADOOP_CONF_DIR='/etc/hadoop/conf' \
#    -e http_port='8080' \
#    -e keytab_user='' \
#    -e keytab_location='' \
#    -e ELEPHANT_CONF_DIR='/etc/drelephant/conf' \
#    -v /etc/drelephant/conf:/usr/dr-elephant/app-conf
#    edf/dr-elephant /bin/bash


