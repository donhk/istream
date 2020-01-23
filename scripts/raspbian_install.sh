#!/bin/bash
export ISTREAM_HOME=$(pwd)
export FFMPEG_FILE=ffmpeg-release-arm64-static.tar.xz

if [[ "${ISTREAM_HOME}" == "*scripts" ]]; then
    export ISTREAM_HOME=$(dirname ${ISTREAM_HOME})
fi

export SCRIPTS_HOME=${ISTREAM_HOME}/scripts

# checking the env file is properly placed
if [[ -f ".env" ]]; then
    echo "Configuring environment"
else
    echo "Please update and source .env file"
    cp ${ISTREAM_HOME}/.env.src ${ISTREAM_HOME}/.env
    chown $(logname):$(logname) ${ISTREAM_HOME}/.env
    chmod 700 ${ISTREAM_HOME}/.env
    cat ${ISTREAM_HOME}/.env
    exit 1
fi

if [[ $(id -u) -ne 0 ]]; then
    echo "This script needs to be run with sudo"
    exit 1
fi

source .env

#
# node
# https://linuxize.com/post/how-to-install-node-js-on-raspberry-pi/
echo "Installing software dependencies"
curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt install -y nodejs wget sshfs

sh z_file.sh