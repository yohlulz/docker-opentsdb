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
			ant \
			openssh-server

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
RUN sed -i 's|#AuthorizedKeysFile.*authorized_keys|AuthorizedKeysFile /etc/ssh/keys/authorized_keys|g' /etc/ssh/sshd_config
RUN mkdir -p /etc/ssh/keys && touch /etc/ssh/keys/authorized_keys
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
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

############################# Cleanup
RUN apt-get clean autoremove autoclean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
###########################################

########################## Expose ports
# TSD
EXPOSE 4242
# SSH
EXPOSE 22
###########################################


VOLUME ["/opt/data/tsdb", "/opt/data/cache", "/etc/ssh/keys", "/opt/data/varnish"]

#Start supervisor
CMD ["/opt/opentsdb/bin/startup.sh"]

