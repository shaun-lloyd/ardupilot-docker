# Ardupilot-Docker

A Multistage dockerfile for Ardupilot developement, test, sitl and release.

* Any feedback and guidance welcomed.

# Getting Started
This dockerfile adds the following features:
* use apt-cache-ng to speed up builds.
* cloning ardupilot.
* seperation of development/build/test/sitl environments.
* output of board for upload

# Todo
* automate sitl tests
* git submodule selection.
 * ChibiOS
 * UAVCAN
 * PX4Firmware
 * PX4NuttX
* waf configure options.
* testsuite.
* benchmarks.
* mavlink network config/routing etc.
* vehicle selection
* upload to board
-./waf configure --board <board> --rsync-dest <destination>

# Usage
docker run -it slloydie/ardupilot:latest bash

## local src
docker run -it -v `pwd`:/ardupilot slloydie/ardupilot:latest bash

## local apt-cache-ng/container
docker run -it --build-arg APT_CACHE=http://172.17.0.2:3142 slloydie/ardupilot:latest bash 

## dev environment.
docker run -it --target dev slloydie/ardupilot:latesh bash

## waf build environment
docker run -it --target build-waf slloydie/ardupilot:latest bash

## build for pixhawk4
docker run -it --target build-waf --build-arg AP_BOARD=Pixhawk4

# Environment Variables
| Variable | Default | Example |
| --- | --- | --- |
| APT_CACHE | '' | http://172.2.0.1:3142 for standard apt-cache-ng docker instance. |
| GIT_REPO | https://github.com/ArduPilot/ardupilot.git | https://github.com/your-github-account/ardupilot |
| GIT_BRANCH | master |  |
| AP_BOARD | sitl | |
| AP_VEHICLE | check-all | plane |
| WAF_OPT | check-all | |

# Volumes

# Thanks
* Bret Fisher, for awesome udemy docker coarse. And code review on this project :)
