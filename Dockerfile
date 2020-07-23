FROM ubuntu:18.04 as dev

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_CACHE=
ARG GIT_REPO=https://github.com/ArduPilot/ardupilot.git
ARG GIT_BRANCH=master

RUN if [ ! -z "$APT_CACHE" ]; then echo "Acquire::http { Proxy \"${APT_CACHE}\"; };" >> /etc/apt/apt.conf.d/01proxy; fi
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates rsync lsb-release sudo git software-properties-common cmake

# Create non-root user for pip 
RUN groupadd -g 1000 ardupilot && \
    useradd -d /home/ardupilot -m ardupilot -u 1000 -g 1000 && \
    usermod -a -G dialout ardupilot && \
    echo "ardupilot ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ardupilot && \
    chmod 0440 /etc/sudoers.d/ardupilot

ENV CCACHE_MAXSIZE 1G
ENV USER ardupilot
USER ardupilot
WORKDIR /ardupilot

# ardupilot repo
RUN git config --global core.autocrlf false && \
    git clone "${GIT_REPO}"  /ardupilot && \
    git submodule update --init --recursive && \
    git checkout "${GIT_BRANCH}"

# Bootstrap
ENV SKIP_AP_EXT_ENV=1 SKIP_AP_GRAPHIC_ENV=1 SKIP_AP_COV_ENV=1 SKIP_AP_GIT_CHECK=1
ENV PATH ${PATH}:/usr/lib/ccache:/ardupilot/Tools:/ardupilot/Tools/autotest:/ardupilot/.local/bin

RUN /ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh -y

# add waf alias to ardupilot waf to .bashrc
RUN echo "alias waf=\"/ardupilot/waf\"" >> ~/.bashrc && \
    # Check that local/bin are in PATH for pip --user installed package
    echo "if [ -d \"\$HOME/.local/bin\" ] ; then\nPATH=\"\$HOME/.local/bin:\$PATH\"\nfi" >> ~/.bashrc && \
    . ~/.bashrc

# Cleanup
RUN sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM dev as build-waf

ARG AP_BOARD=sitl
ARG AP_VEHICLE=
ARG WAF_OPT=

# Config
RUN /ardupilot/waf configure --board ${AP_BOARD}

# Build everything and run all tests
RUN /ardupilot/waf ${WAF_OPT} --board ${AP_BOARD}

FROM build-waf as sitl

WORKDIR /ardupilot/ArduPlane
ENTRYPOINT [ "sim_vehicle.py" ]
