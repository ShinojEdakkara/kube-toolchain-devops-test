FROM ubuntu:14.04
MAINTAINER IBM

RUN apt-get update \
    && apt-get install -y \
    wget \
    curl \
    supervisor \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Install JRE

ADD dependencies/ibm-java-jre-8.0-3.0-linux-x86_64_*.tgz /opt/ibm/    
ENV JAVA_HOME /opt/ibm/ibm-java-x86_64-80

COPY dependencies/license-check /opt/ibm/docker/

# Install WebSphere Liberty
ADD dependencies/wlp-base-embeddable-16.0.0.3_*.tar.gz /opt/ibm/

# Create 'appcenter' profile
RUN /opt/ibm/wlp/bin/server create appcenter \
    && rm -rf /opt/ibm/wlp/usr/servers/.classCache \
    && rm -rf /opt/ibm/wlp/usr/servers/appcenter/apps/* \
    && mkdir -p /opt/ibm/MobileFirst/licenses 
    
# SSH
RUN mkdir -p /var/run/sshd &&\
    mkdir -p /root/.ssh/ &&\
    mkdir -p /root/sshkey/ &&\
    touch /root/.ssh/authorized_keys &&\
    sed -i 's/session \+required \+pam_loginuid\.so/session optional pam_loginuid.so/' /etc/pam.d/sshd &&\
    sed -i 's/.*PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config &&\
    sed -i 's/.*UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config &&\
    sed -i 's/.*ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config

ADD mfpf-libs/mfp-appcenter.tgz /
COPY licenses/ /opt/ibm/MobileFirst/licenses

# Set password length and expiry for compliance with Vulnerability Advisor
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs \
     && sed -i 's/sha512/sha512  minlen=8/' /etc/pam.d/common-password

RUN chmod u+x /opt/ibm/docker/license-check \
    && chmod u+x /opt/ibm/wlp/bin/liberty-run \
    && chmod +x /root/bin/run_supervisord \
    && mkdir /var/log/rsyslog \
    && chown syslog /var/log/rsyslog

ENV LICENSE accept

ENTRYPOINT ["/bin/sh", "-c" ]
CMD ["/root/bin/run_supervisord"]

COPY usr/bin/mfp-appcenter-init /opt/ibm/wlp/bin/
RUN chmod u+x /opt/ibm/wlp/bin/mfp-appcenter-init
COPY usr/security /opt/ibm/wlp/usr/servers/appcenter/resources/security/
COPY usr/jre-security /opt/ibm/ibm-java-x86_64-80/jre/lib/security/
COPY usr/env /opt/ibm/wlp/usr/servers/appcenter/
COPY usr/ssh /root/sshkey/
COPY usr/config/*.xml /opt/ibm/wlp/usr/servers/appcenter/configDropins/overrides/

RUN apt-get update \
	&& apt-get upgrade -y 