FROM ubuntu:18.04 as dev

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_CACHE=

RUN [ -z "$APT_CACHE" ] && echo "Acquire::http { Proxy \"${APT_CACHE}\"; };" >> /etc/apt/apt.conf.d/01proxy
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
WORKDIR /usr/src/ardupilot

# ardupilot repo
RUN git config --global core.autocrlf false && \
    git clone https://github.com/ArduPilot/ardupilot.git /usr/src/ardupilot && \
    git submodule update --init --recursive

# Bootstrap
ENV SKIP_AP_EXT_ENV=1 SKIP_AP_GRAPHIC_ENV=1 SKIP_AP_COV_ENV=1 SKIP_AP_GIT_CHECK=1
ENV PATH ${PATH}:/usr/lib/ccache:/ardupilot/Tools:/ardupilot/Tools/autotest:/ardupilot/.local/bin

RUN /usr/src/ardupilot/Tools/environment_install/install-prereqs-ubuntu.sh -y

# add waf alias to ardupilot waf to .bashrc
RUN echo "alias waf=\"/ardupilot/waf\"" >> ~/.bashrc && \
    # Check that local/bin are in PATH for pip --user installed package
    echo "if [ -d \"\$HOME/.local/bin\" ] ; then\nPATH=\"\$HOME/.local/bin:\$PATH\"\nfi" >> ~/.bashrc && \
    . ~/.bashrc

# config ccache
RUN cd /usr/lib/ccache && \
    sudo ln -s /usr/bin/ccache arm-none-eabi-g++ && \
    sudo ln -s /usr/bin/ccache arm-none-eabi-gcc

# Cleanup
RUN sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

FROM dev as build

# build jsm-sim
# RUN mkdir /usr/src/jsmsim/build && cd /usr/src/jsmsim/build && \
#     cmake -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native -mtune=native" -DCMAKE_C_FLAGS_RELEASE="-O3 -march=native -mtune=native" -DCMAKE_BUILD_TYPE=Release .. && \
#     make 

# Configure ardupilot
RUN ./waf configure

# Build ardupilot
RUN ./waf

# Clean
# RUN ./waf clean

FROM build as sitl

WORKDIR /usr/src/ardupilot/ArduPilot
ENTRYPOINT [ "sim_vehicle.py" ]

FROM ubuntu:18.04 as release

COPY --from=builder /build /usr
