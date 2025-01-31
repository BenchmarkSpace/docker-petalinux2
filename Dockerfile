# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

FROM ubuntu:18.04

LABEL version="1.0" description="Geniux builder" maintainer="carles.fernandez@cttc.es"

# build with "docker build --build-arg PETA_VERSION=2020.2 --build-arg PETA_RUN_FILE=petalinux-v2020.2-final-installer.run -t docker_petalinux2:2020.2 ."
# or "docker build --build-arg PETA_VERSION=2020.1 --build-arg PETA_RUN_FILE=petalinux-v2020.1-final-installer.run --build-arg VIVADO_INSTALLER=Xilinx_Unified_2020.1_0602_1208.tar.gz -t docker_petalinux2:2020.1 ."

# install dependences:

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  autoconf \
  bc \
  bison \
  build-essential \
  ca-certificates \
  chrpath \
  cpio \
  curl \
  dbus \
  dbus-x11 \
  debianutils \
  diffstat \
  expect \
  flex \
  fonts-droid-fallback \
  fonts-ubuntu-font-family-console \
  gawk \
  gcc-multilib \
  git \
  gnupg \
  gtk2-engines \
  gzip \
  iproute2 \
  iputils-ping \
  kmod \
  lib32z1-dev \
  libegl1-mesa \
  libglib2.0-dev \
  libgtk2.0-0 \
  libjpeg62-dev \
  libncurses5-dev \
  libsdl1.2-dev \
  libselinux1 \
  libssl-dev \
  libtool \
  libtool-bin \
  locales \
  lsb-release \
  lxappearance \
  nano \
  net-tools \
  openssl \
  pax \
  pylint3 \
  python3 \
  python3-pexpect \
  python3-pip \
  python3-git \
  python3-jinja2 \
  repo \
  rsync \
  screen \
  socat \
  sudo \
  texinfo \
  tftpd \
  tofrodos \
  ttf-ubuntu-font-family \
  u-boot-tools \
  ubuntu-gnome-default-settings \
  unzip \
  update-inetd \
  vim \
  wget \
  xorg \
  xterm \
  xvfb \
  xxd \
  zlib1g-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

#RUN --mount=type=ssh git clone git@github.com:myorg/myproject.git myproject
#RUN echo "Host *.trabe.io\n\tStrictHostKeyChecking no\n" >> /home/user/.ssh/config

#install cmake 3.23.2
RUN wget https://gitlab.kitware.com/cmake/cmake/-/archive/v3.23.2/cmake-v3.23.2.tar.gz
RUN tar -xvzf ./cmake-v3.23.2.tar.gz
WORKDIR /cmake-v3.23.2
RUN ./bootstrap
RUN make install
WORKDIR /
RUN rm -rf /cmake-v3.23.2*

RUN dpkg --add-architecture i386 && apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  zlib1g:i386 libc6-dev:i386 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ARG PETA_VERSION
ARG PETA_RUN_FILE

RUN locale-gen en_US.UTF-8 && update-locale

# make a petalinux user
RUN adduser --disabled-password --gecos '' petalinux && \
  usermod -aG sudo petalinux && \
  echo "petalinux ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY accept-eula.sh ${PETA_RUN_FILE} /

# run the install
RUN chmod a+rx /${PETA_RUN_FILE} && \
  chmod a+rx /accept-eula.sh && \
  mkdir -p /opt/Xilinx && \
  chmod 777 /tmp /opt/Xilinx && \
  cd /tmp && \
  sudo -u petalinux -i /accept-eula.sh /${PETA_RUN_FILE} /opt/Xilinx/petalinux && \
  rm -f /${PETA_RUN_FILE} /accept-eula.sh

ARG VIVADO_INSTALLER

COPY install_config.txt /vivado-installer/
COPY Xilinx_Unified_${PETA_VERSION}_*.tar.gz /vivado-installer/

RUN \
  if [ "$VIVADO_INSTALLER" ] ; then \
    cat /vivado-installer/${VIVADO_INSTALLER} | tar zx --strip-components=1 -C /vivado-installer && \
    /vivado-installer/xsetup \
      --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
      --batch Install \
      --config /vivado-installer/install_config.txt && \
    rm -rf /vivado-installer ; \
  fi

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

USER petalinux
ENV HOME /home/petalinux
ENV LANG en_US.UTF-8
RUN mkdir /home/petalinux/project
WORKDIR /home/petalinux/project
#WORKDIR /app

ENV TERM xterm-256color

# add petalinux tools to path

# Source settings at login
USER root

RUN echo "/usr/sbin/in.tftpd --foreground --listen --address [::]:69 --secure /tftpboot" >> /etc/profile && \
  echo ". /opt/Xilinx/petalinux/settings.sh" >> /etc/profile && \
  if [ "$VIVADO_INSTALLER" ] ; then \
    echo ". /tools/Xilinx/Vivado/${PETA_VERSION}/settings64.sh" >> /etc/profile ; \
  fi && \
  echo ". /etc/profile" >> /root/.profile

EXPOSE 69/udp

USER petalinux

ENTRYPOINT ["/bin/sh", "-l"]
