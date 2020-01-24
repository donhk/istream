#!/bin/bash

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

export FSTAB=/etc/fstab
export MUID=$(id -u ${LOCAL_USERNAME})
export MGID=$(id -g ${LOCAL_USERNAME})
export OPTIONS="noauto,x-systemd.automount,_netdev,allow_other,default_permissions,reconnect,nonempty,uid=${MUID},gid=${MGID},IdentityFile=${LOCAL_SERVER_IDENTITY}"
echo "sshfs#${REMOTE_SERVER_USER}@${REMOTE_SERVER_ADDRES}:${REMOTE_SERVER_DIRECTORY} ${LOCAL_SERVER_DIRECTORY} fuse ${OPTIONS} 0 0" >> ${FSTAB}

mount -a

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
REMOTE_SERVER_DIRECTORY=${REMOTE_SERVER_DIRECTORY}
AVAILABLE_STORAGE=${AVAILABLE_STORAGE}
LOCAL_SERVER_DIRECTORY=${LOCAL_SERVER_DIRECTORY}
LOCAL_USERNAME=${LOCAL_USERNAME}
CLEAN_DIR_INTERVAL=${CLEAN_DIR_INTERVAL}
MAX_USED_SPACE=${MAX_USED_SPACE}
RECONNECT_INTERVAL=${RECONNECT_INTERVAL}
SEGMENT_DURATION=${SEGMENT_DURATION}
FFMPEG_HOME=${STREAM_TOOLS}/ffmpeg
EOF

chmod 700 ${APP_PROPERTIES}
chown -R ${LOCAL_USERNAME}:${LOCAL_USERNAME} ${APP_PROPERTIES}
