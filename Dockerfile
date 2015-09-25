FROM centos:6.6
MAINTAINER NalinGarg

ADD cloudera.repo /etc/yum.repos.d/

# increase timeouts to avoid "No more mirrors to try" if yum repos are busy for a few minutes
RUN echo "retries=0" >> /etc/yum.conf
RUN echo "timeout=60" >> /etc/yum.conf


USER root

# install dev tools
RUN echo running dev tools
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y curl which tar sudo openssh-server openssh-clients rsync
# update libselinux. see https://github.com/sequenceiq/hadoop-docker/issues/14
RUN yum update -y libselinux

RUN yum install -y tar git curl bind-utils unzip

#java
RUN echo install java 
RUN yum install -y wget
RUN wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jdk-7u45-linux-x64.rpm -O jdk-7u45-linux-x64.rpm
RUN rpm -i jdk-7u45-linux-x64.rpm
RUN rm jdk-7u45-linux-x64.rpm
RUN alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_45/bin/java 200000

ENV JAVA_HOME /usr/java/jdk1.7.0_45/
ENV PATH $PATH:$JAVA_HOME/bin

#Namenode install
RUN yum install -y hadoop-hdfs-namenode

#make directories
RUN mkdir -p /data/1/dfs/{dn,nn} 
RUN mkdir -p /data/1/yarn/{local,logs} 
RUN chown -R hdfs:hdfs /data/1/dfs 
RUN chown -R yarn:yarn /data/1/yarn 
 

RUN mkdir -p /tmp
RUN chown -R hdfs:hadoop /tmp
RUN chmod 1777 -R /tmp

RUN mkdir -p /user/history
RUN chown -R mapred:hadoop /user/history
RUN chmod 1777 -R /user/history

RUN mkdir -p /var/log/hadoop-yarn
RUN chown yarn:mapred /var/log/hadoop-yarn

ADD hadoop-env.sh /etc/hadoop/conf/

# Fully distributed

RUN rm -rf /etc/hadoop/conf/core-site.xml
RUN rm -rf /etc/hadoop/conf/hdfs-site.xml
RUN rm -rf /etc/hadoop/conf/yarn-site.xml

ADD core-site.xml /etc/hadoop/conf/
ADD mapred-site.xml /etc/hadoop/conf/
ADD yarn-site.xml /etc/hadoop/conf/
ADD hdfs-site.xml /etc/hadoop/conf/

RUN sed -i 's/\[NameNode_FQDN\]/namenode/g' /etc/hadoop/conf/core-site.xml
RUN sed -i 's/\[NameNode_FQDN\]/namenode/g' /etc/hadoop/conf/hdfs-site.xml
RUN sed -i 's/\[JobHistoryServer_FQDN\]/resourcemanager/g' /etc/hadoop/conf/mapred-site.xml
RUN sed -i 's/\[ResourceManager_FQDN\]/resourcemanager/g' /etc/hadoop/conf/yarn-site.xml

ADD ipresolv.sh /home/
RUN chmod 777 /home/ipresolv.sh
RUN ./home/ipresolv.sh

USER hdfs
#RUN hadoop namenode -format

USER root

#RUN service hadoop-hdfs-namenode start


#Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 1004 1006 50745 8020 8022 50470 50090

#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088 8090 8041 8044 10020 10033 13562 19888 19890
#Other ports
EXPOSE 49707 2122 
