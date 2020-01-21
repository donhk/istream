#!/bin/bash
export ISTREAM_HOME=$(pwd)

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
# https://linuxize.com/post/how-to-install-node-js-on-centos-7/
echo "Installing software dependencies"
curl -sL https://rpm.nodesource.com/setup_10.x | bash -
yum install -y nodejs wget sshfs sshpass

#
# ffmpeg 4.2.2
# https://johnvansickle.com/ffmpeg/
echo "Installing some tools"
export STREAM_TOOLS=${ISTREAM_HOME}/tools

rm -rf ${STREAM_TOOLS}/ffmpeg
mkdir -p ${STREAM_TOOLS}/ffmpeg
wget -O ${STREAM_TOOLS}/ffmpeg-release-amd64-static.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz
tar -xf ${STREAM_TOOLS}/ffmpeg-release-amd64-static.tar.xz -C ${STREAM_TOOLS}/ffmpeg
rm ${STREAM_TOOLS}/ffmpeg-release-amd64-static.tar.xz
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${STREAM_TOOLS}

#
# sshfs
#
export MUID=$(id -u ${LOCAL_USERNAME})
export MGID=$(id -g ${LOCAL_USERNAME})
export OPTIONS="allow_other,default_permissions,reconnect,nonempty,uid=${MUID},gid=${MGID}"
export CMD_IPREFIX=
if [[ "${LOCAL_SERVER_IDENTITY}" != "" ]]; then
    export OPTIONS="${OPTIONS},IdentityFile=${LOCAL_SERVER_IDENTITY}"
else
    export CMD_IPREFIX="sshpass -p ${REMOTE_SERVER_PASS}"
fi
chmod 766 /etc/fuse.conf
echo "user_allow_other" >> /etc/fuse.conf
# make sure it is not being used
fusermount -u ${LOCAL_SERVER_DIRECTORY}
echo ${CMD_IPREFIX} sshfs ${REMOTE_SERVER_USER}@${REMOTE_SERVER_ADDRES}:${REMOTE_SERVER_DIRECTORY} ${LOCAL_SERVER_DIRECTORY} -o ${OPTIONS}
${CMD_IPREFIX} sshfs ${REMOTE_SERVER_USER}@${REMOTE_SERVER_ADDRES}:${REMOTE_SERVER_DIRECTORY} ${LOCAL_SERVER_DIRECTORY} -o ${OPTIONS}

#
# deploy project
#
su - ${LOCAL_USERNAME} <<EOF
cd ${ISTREAM_HOME}
npm install
mkdir -p ${LOCAL_SERVER_DIRECTORY}
EOF
npm install -g .

#
# create unit
#
export UNIT_FILE=/etc/systemd/system/istream.service
touch ${UNIT_FILE}
truncate --size 0 ${UNIT_FILE}

cat <<EOF >>${UNIT_FILE}
[Unit]
Description=istream service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=${LOCAL_USERNAME}
ExecStart=/usr/bin/istream i

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

#
# creating app properties
#
export APP_PROPERTIES=.app.properties
cat <<EOF >>${APP_PROPERTIES}
CAM_USER=${CAM_USER}
CAM_PASS=${CAM_PASS}
REMOTE_SERVER_ADDRES=${REMOTE_SERVER_ADDRES}
REMOTE_SERVER_USER=${REMOTE_SERVER_USER}
REMOTE_SERVER_PASS=${REMOTE_SERVER_PASS}
REMOTE_SERVER_DIRECTORY=${REMOTE_SERVER_DIRECTORY}
AVAILABLE_STORAGE=${AVAILABLE_STORAGE}
LOCAL_SERVER_DIRECTORY=${LOCAL_SERVER_DIRECTORY}
LOCAL_SERVER_IDENTITY=${LOCAL_SERVER_IDENTITY}
LOCAL_USERNAME=${LOCAL_USERNAME}
CLEAN_DIR_INTERVAL=${CLEAN_DIR_INTERVAL}
MAX_USED_SPACE=${MAX_USED_SPACE}
RECONNECT_INTERVAL=${RECONNECT_INTERVAL}
SEGMENT_DURATION=${SEGMENT_DURATION}
EOF

chmod 700 ${APP_PROPERTIES}
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${APP_PROPERTIES}
