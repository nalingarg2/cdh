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

 java
RUN echo install java 
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
 

RUN mkdir /tmp
RUN chown -R hdfs:hadoop /tmp
RUN chmod 1777 -R /tmp

RUN mkdir /user/history
RUN chown -R mapred:hadoop /user/history
RUN chmod 1777 -R /user/history

RUN mkdir /var/log/hadoop-yarn
RUN chown yarn:mapred /var/log/hadoop-yarn

#hadoop


ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD core-site.xml /etc/hadoop/core-site.xml.template
RUN sed s/HOSTNAME/localhost/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

RUN $HADOOP_PREFIX/bin/hdfs namenode -format

RUN service hadoop-hdfs-namenode start


# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122   


