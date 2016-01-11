FROM ubuntu


###################### System reqs
# install requirements
ENV DEBIAN_FRONTEND noninteractive
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN \
  apt-get update && \
  apt-get install -y python-setuptools \
			python-software-properties \
			software-properties-common \
			curl \
			nano \
			vim \
			htop \
			tar \
			gnuplot \
			git \
			make \
			automake \
			supervisor \
			jq \
			ant
			

# install java
RUN \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java7-installer

# set JAVA home
ENV JAVA_HOME /usr/lib/jvm/java-7-oracle

# For nano to work properly
ENV TERM=xterm
############################################

############################## TSD specific
# Switch to root user
USER root

# Install TSD
RUN git clone -b tts_maintenance_v2.1.0 --single-branch https://github.com/toraTSD/opentsdb /opt/opentsdb && \
	chmod +x /opt/opentsdb/bootstrap /opt/opentsdb/build.sh /opt/opentsdb/build-aux/*.sh && \
	cd /opt/opentsdb && ./build.sh && \
	mkdir -p /opt/opentsdb/bin /opt/data/cache /opt/data/tsdb /opt/data/tsdb/plugins && \
	ln -s /opt/opentsdb/build/tsdb /opt/opentsdb/bin/tsdb

# Add TSD to path
ENV PATH=/opt/opentsdb/build:$PATH
############################################

############################ Modify configs
ADD etc/conf/* /opt/data/tsdb/
ADD etc/bin/* /opt/opentsdb/bin/
ADD etc/supervisord.conf /etc/supervisord.conf
ADD etc/supervisord.d/* /etc/supervisord.d/
###########################################

########################## Expose ports
# TSD
EXPOSE 4242
###########################################


VOLUME ["/opt/data/tsdb", "/opt/data/cache"]

#Start supervisor
CMD ["/opt/opentsdb/bin/startup.sh"]

