FROM ubuntu:15.10
MAINTAINER Freddy Vega

# ENV DEBIAN_FRONTEND noninteractive
# ENV DEBCONF_NONINTERACTIVE_SEEN true

# Update the repositories
RUN apt-get -yqq update

# Upgrade packages
RUN apt-get -yqq upgrade

#================================================
# Customize sources for apt-get
#================================================
RUN  echo "deb http://archive.ubuntu.com/ubuntu vivid main universe\n" > /etc/apt/sources.list \
  && echo "deb http://archive.ubuntu.com/ubuntu vivid-updates main universe\n" >> /etc/apt/sources.list

#========================
# Miscellaneous packages
# Includes minimal runtime used for executing non GUI Java programs
#========================
RUN apt-get update -qqy \
  && apt-get -qqy --no-install-recommends install \
    ca-certificates \
    openjdk-8-jre-headless \
    sudo \
    unzip \
    wget \
    openssl \
    dnsutils \
    curl \
    xvfb \
    fonts-ipafont-gothic \
    xfonts-100dpi \
    xfonts-75dpi \
    xfonts-scalable \
    xfonts-cyrillic \
    x11vnc \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i 's/securerandom\.source=file:\/dev\/random/securerandom\.source=file:\/dev\/urandom/' ./usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/java.security

#=============
# Set timezone
#=============
ENV TZ "US/Eastern"
RUN echo "US/Eastern" | sudo tee /etc/timezone
RUN dpkg-reconfigure --frontend noninteractive tzdata

#=======================
# Install xvfb and fonts
#=======================
# RUN apt-get -yqq install xvfb fonts-ipafont-gothic xfonts-100dpi xfonts-75dpi xfonts-scalable xfonts-cyrillic

#============
# Install VNC
#============
# RUN apt-get -yqq install x11vnc
RUN mkdir -p ~/.vnc

#=======================
# Configure VNC Password
#=======================
RUN x11vnc -storepasswd selenium ~/.vnc/passwd

#=================
# Selenium Install
#=================
RUN  mkdir -p /opt/selenium \
  && wget --no-verbose http://selenium-release.storage.googleapis.com/2.52/selenium-server-standalone-2.52.0.jar -O /opt/selenium/selenium-server-standalone.jar

#========================================
# Add normal user with passwordless sudo
#========================================
RUN sudo useradd seluser --shell /bin/bash --create-home \
  && sudo usermod -a -G sudo seluser \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'seluser:secret' | chpasswd


#========================
# Selenium Configuration
#========================

EXPOSE 4444 5900

ENV GRID_NEW_SESSION_WAIT_TIMEOUT -1
ENV GRID_JETTY_MAX_THREADS -1
ENV GRID_NODE_POLLING  5000
ENV GRID_CLEAN_UP_CYCLE 5000
ENV GRID_TIMEOUT 30000
ENV GRID_BROWSER_TIMEOUT 0
ENV GRID_MAX_SESSION 5
ENV GRID_UNREGISTER_IF_STILL_DOWN_AFTER 30000

COPY generate_config /opt/selenium/generate_config
COPY entry_point.sh /opt/bin/entry_point.sh
RUN chown -R seluser /opt/selenium
RUN chmod +x /opt/bin/entry_point.sh
RUN chmod +x /opt/selenium/generate_config

USER seluser

CMD ["/opt/bin/entry_point.sh"]

