FROM ubuntu:18.04 as dev
# Ubuntu Base ardupilot development image
# docker build --target dev --build-arg GIT_REPO=https://github.com/shaun-lloyd/ardupilot/ardupilot.git .
# - bootstapped with std toolchain
# - NO build has been done.

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_CACHE=
ARG GIT_REPO=https://github.com/ArduPilot/ardupilot.git
ARG GIT_BRANCH=master
ARG USER_NAME=ardupilot
ARG USER_UID=1000
ARG USER_GID=1000

RUN if [ ! -z "$APT_CACHE" ]; then echo "Acquire::http { Proxy \"${APT_CACHE}\"; };" >> /etc/apt/apt.conf.d/01proxy; fi
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates rsync lsb-release git software-properties-common cmake gosu && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create non-root user for pip 
RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -d /home/${USER_NAME} -m ${USER_NAME} -u ${USER_UID} -g ${USER_GID} && \
    usermod -a -G dialout ${USER_NAME} 

ENV CCACHE_MAXSIZE 1G
ENV USER ${USER_NAME}
USER ${USER_NAME}

WORKDIR /ardupilot

RUN gosu root chown ${USER_NAME}:${USER_NAME} -R /ardupilot

RUN git config --global core.autocrlf false && \
    git clone --depth 1 "${GIT_REPO}"  /ardupilot && \
    git submodule update --init --recursive --depth 1 && \
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

FROM dev as build-waf
# Build from standard ubuntu base image.
# docker build --target build-waf --build-arg AP_BOARD=CubeOrange .
# - AP_BOARD= ardupilot board type.
# - AP_VEHICLE= specific vehical "all" is default.
# - WAF_OPT= arguments parsed to waf.

ARG AP_BOARD=sitl
ARG AP_VEHICLE=
ARG WAF_OPT=

# Config
RUN /ardupilot/waf configure --board ${AP_BOARD}

# Build everything and run all tests
RUN /ardupilot/waf ${WAF_OPT} --board ${AP_BOARD}

FROM build-waf as test-sitl-plane
# Run SITL.
# docker build --target test-sitl .
# Run sitl-plane.

WORKDIR /ardupilot/ArduPlane
CMD sim_vehicle.py
ENTRYPOINT [ "sim_vehicle.py" ]
