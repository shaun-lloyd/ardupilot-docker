# Ardupilot-Docker

A Multistage dockerfile for Ardupilot developement, test, sitl and release.

# Getting Started
This dockerfile adds the following features:
* use apt-cache-ng to speed up builds.
* cloning ardupilot.
* seperation of development/build/test/sitl environments.
* output of board for upload

# Todo
* automate sitl tests

# Usage
docker run 

# Environment Variables
APT_CACHE   eg. 172.2.0.1:3142 for standard apt-cache-ng docker instance.

# Volumes

# Thanks
* Bret Fisher, for awesome udemy docker coarse. And code review on this project :)
