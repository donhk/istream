#!/bin/bash

#
# ffmpeg 4.2.2
# https://johnvansickle.com/ffmpeg/
echo "Installing some tools"
export STREAM_TOOLS=${ISTREAM_HOME}/tools

rm -rf ${STREAM_TOOLS}/ffmpeg
mkdir -p ${STREAM_TOOLS}/ffmpeg
wget -O ${STREAM_TOOLS}/${FFMPEG_FILE} https://johnvansickle.com/ffmpeg/releases/${FFMPEG_FILE}
tar -xf ${STREAM_TOOLS}/${FFMPEG_FILE} -C ${STREAM_TOOLS}/ffmpeg --strip 1
rm ${STREAM_TOOLS}/${FFMPEG_FILE}
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${STREAM_TOOLS}

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

su - ${LOCAL_USERNAME} <<EOF
ssh-keygen -R ${REMOTE_SERVER_ADDRES}
ssh-keyscan -H ${REMOTE_SERVER_ADDRES} >> ~/.ssh/known_hosts
EOF

# make sure it is not being used
fusermount -u ${LOCAL_SERVER_DIRECTORY}

export MUID=$(id -u ${LOCAL_USERNAME})
export MGID=$(id -g ${LOCAL_USERNAME})
export OPTIONS="allow_other,default_permissions,reconnect,nonempty,uid=${MUID},gid=${MGID}"
export CMD_IPREFIX=
if [[ "${LOCAL_SERVER_IDENTITY}" != "" ]]; then
    export OPTIONS="${OPTIONS},IdentityFile=${LOCAL_SERVER_IDENTITY}"
else
    export OPTIONS="${OPTIONS},password_stdin"
    export CMD_IPREFIX="echo ${REMOTE_SERVER_PASS}"
fi

${CMD_IPREFIX} | sshfs ${REMOTE_SERVER_USER}@${REMOTE_SERVER_ADDRES}:${REMOTE_SERVER_DIRECTORY} ${LOCAL_SERVER_DIRECTORY} -o ${OPTIONS}

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
RestartSec=90
User=${LOCAL_USERNAME}
ExecStart=/usr/bin/istream i
StartLimitInterval=200
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

#
# creating app properties
#
export APP_PROPERTIES=bin/.app.properties
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
FFMPEG_HOME=${STREAM_TOOLS}/ffmpeg
EOF

chmod 700 ${APP_PROPERTIES}
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${APP_PROPERTIES}
