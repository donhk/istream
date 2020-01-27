#!/bin/bash
#
#   CentOS Linux release 7.7.1908 (Core)
#   3.10.0-1062.9.1.el7.x86_64 x86_64
# ----------------------------------------------------------------
# istream - centos7_install.sh
#
# Copyright (c) 2020 Frederick Alvarez, All rights reserved.
# Released under the MIT license
# Date: 2020-01-26
# ----------------------------------------------------------------
export ISTREAM_HOME=$(pwd)
export FFMPEG_FILE=ffmpeg-release-amd64-static.tar.xz

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
# install dependencies
# https://linuxize.com/post/how-to-install-node-js-on-centos-7/
echo "Installing software dependencies"
curl -sL https://rpm.nodesource.com/setup_10.x | bash -
yum install -y nodejs wget sshfs sshpass

#
# ffmpeg 4.2.2
# https://johnvansickle.com/ffmpeg/
echo "Installing some tools";

export STREAM_TOOLS=${ISTREAM_HOME}/tools

rm -rf ${STREAM_TOOLS}/ffmpeg
mkdir -p ${STREAM_TOOLS}/ffmpeg
wget -O ${STREAM_TOOLS}/${FFMPEG_FILE} https://johnvansickle.com/ffmpeg/releases/${FFMPEG_FILE}
tar -xf ${STREAM_TOOLS}/${FFMPEG_FILE} -C ${STREAM_TOOLS}/ffmpeg --strip 1
rm ${STREAM_TOOLS}/${FFMPEG_FILE}
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${STREAM_TOOLS}

#
# ssh passwordless connection
#
# for root to allow mounting without prompt
if [[ "" == "$(ssh-keygen -H -F ${REMOTE_SERVER_ADDRES})" ]]; then
    echo 'Adding remote machine to known_hosts for root';
    mkdir -p ${HOME}/.ssh/
    ssh-keyscan -t rsa -H ${REMOTE_SERVER_ADDRES} >> ${HOME}/.ssh/known_hosts
else
    echo "remote key already present on root's known_host";
fi

# for non-root to allow mounting without prompt
tmpfile=$(mktemp)
cat <<EOT >> ${tmpfile}
#!/bin/bash
export LOCAL_SERVER_IDENTITY=\${HOME}/.ssh/id_rsa
export REMOTE_SERVER_ADDRES=${REMOTE_SERVER_ADDRES}
export REMOTE_SERVER_USER=${REMOTE_SERVER_USER}
export CONFIGURE_PASSWORDLESS_SSH=${CONFIGURE_PASSWORDLESS_SSH}
export REMOTE_SERVER_PASS=${REMOTE_SERVER_PASS}

if [[ -f "\${LOCAL_SERVER_IDENTITY}" ]]; then
    echo "id_rsa exists";
else
    echo "creating id_rsa";
    ssh-keygen -q -t rsa -N '' -f \${LOCAL_SERVER_IDENTITY} 2>/dev/null <<< y >/dev/null
fi

if [[ "" == "\$(ssh-keygen -H -F \${REMOTE_SERVER_ADDRES})" ]]; then
    echo 'Adding remote machine to known_hosts';
    ssh-keyscan -t rsa -H \${REMOTE_SERVER_ADDRES} >> \${HOME}/.ssh/known_hosts
else
    echo 'remote key already present on known_hosts';
fi

if [[ "yes" == "\${CONFIGURE_PASSWORDLESS_SSH}" ]]; then
    echo 'Copying pub key to server';
    sshpass -p \${REMOTE_SERVER_PASS} ssh-copy-id -i \${HOME}/.ssh/id_rsa.pub \${REMOTE_SERVER_USER}@\${REMOTE_SERVER_ADDRES}
else
     echo 'Assuming passwordless ssh woth server'
fi
EOT

chmod 755 ${tmpfile}
chown ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${tmpfile}
sudo -u ${LOCAL_USERNAME} bash -c ${tmpfile}
rm ${tmpfile}

#
# sshfs
#
export FUSE_FILE=/etc/fuse.conf

if grep -q "^user_allow_other" "${FUSE_FILE}"; then
    echo "All set with ${FUSE_FILE}";
else
    chmod 766 ${FUSE_FILE}
    echo "user_allow_other" >> /etc/fuse.conf
fi

# make sure it is not being used
fusermount -u ${LOCAL_SERVER_DIRECTORY}

export MAIN_HOME=$(eval echo ~${LOCAL_USERNAME})
export LOCAL_SERVER_IDENTITY=${MAIN_HOME}/.ssh/id_rsa
export MUID=$(id -u ${LOCAL_USERNAME})
export MGID=$(id -g ${LOCAL_USERNAME})
export OPTIONS="x-systemd.automount,_netdev,ServerAliveInterval=30,ServerAliveCountMax=5,allow_other,default_permissions,reconnect,nonempty,uid=${MUID},gid=${MGID},IdentityFile=${LOCAL_SERVER_IDENTITY}"

#export FSTAB=/etc/fstab
#echo "sshfs#${REMOTE_SERVER_USER}@${REMOTE_SERVER_ADDRES}:${REMOTE_SERVER_DIRECTORY} ${LOCAL_SERVER_DIRECTORY} fuse ${OPTIONS} 0 0" >> ${FSTAB}

export SERVICE_NAME=$(echo "${LOCAL_SERVER_DIRECTORY}" | tr / -)
export SERVICE_NAME=${SERVICE_NAME:1}
export SSTREAM_FILE=/usr/lib/systemd/system/${SERVICE_NAME}.mount

echo ${SSTREAM_FILE};

touch ${SSTREAM_FILE}
truncate --size 0 ${SSTREAM_FILE}

cat <<EOF >>${SSTREAM_FILE}
[Unit]
Description=sstream sshfs for istream
After=network.target

[Mount]
What=${REMOTE_SERVER_USER}@${REMOTE_SERVER_ADDRES}:${REMOTE_SERVER_DIRECTORY}
Where=${LOCAL_SERVER_DIRECTORY}
Type=fuse.sshfs
Options=${OPTIONS}
TimeoutSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ${SERVICE_NAME}.mount


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
export ISTREAM_SERVICE=istream.service
export UNIT_FILE=/etc/systemd/system/${ISTREAM_SERVICE}

touch ${UNIT_FILE}
truncate --size 0 ${UNIT_FILE}

cat <<EOF >>${UNIT_FILE}
[Unit]
Description=istream service
After=sstream.mount

[Service]
Type=simple
Restart=always
RestartSec=90
User=${LOCAL_USERNAME}
ExecStart=/usr/bin/istream i
StartLimitInterval=200
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable istream.service

echo "######################################################";
echo "#                                                     ";
echo "#   Run the below commands to start the recording     ";
echo "#   >1  sudo systemctl start ${SERVICE_NAME}.mount    ";
echo "#   >2  sudo systemctl start ${ISTREAM_SERVICE}       ";
echo "#                                                     ";
echo "######################################################";

#
# creating app properties
#

export APP_PROPERTIES=bin/.app.properties

cat <<EOF >>${APP_PROPERTIES}
CAM_USER=${CAM_USER}
CAM_PASS=${CAM_PASS}
REMOTE_SERVER_DIRECTORY=${REMOTE_SERVER_DIRECTORY}
AVAILABLE_STORAGE=${AVAILABLE_STORAGE}
LOCAL_SERVER_DIRECTORY=${LOCAL_SERVER_DIRECTORY}
LOCAL_USERNAME=${LOCAL_USERNAME}
CLEAN_DIR_INTERVAL=${CLEAN_DIR_INTERVAL}
MAX_USED_SPACE=${MAX_USED_SPACE}
RECONNECT_INTERVAL=${RECONNECT_INTERVAL}
SEGMENT_DURATION=${SEGMENT_DURATION}
FFMPEG_HOME=${STREAM_TOOLS}/ffmpeg
BROADCAST_NIC=${BROADCAST_NIC}
EOF

chmod 700 ${APP_PROPERTIES}
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${APP_PROPERTIES}

