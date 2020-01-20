#!/usr/bin/bash
export ISTREAM_HOME=`pwd`
if  [[ "$ISTREAM_HOME" == "*script" ]] ;
then
    export ISTREAM_HOME=$(dirname $ISTREAM_HOME)
fi

sh validations.sh

# node
# https://linuxize.com/post/how-to-install-node-js-on-centos-7/
curl -sL https://rpm.nodesource.com/setup_10.x | bash -
yum install -y nodejs wget sshfs sshpass

# ffmpeg 4.2.2
# https://johnvansickle.com/ffmpeg/
mkdir tools
wget -O $(ISTREAM_HOME)/tools/ffmpeg-release-arm64-static.tar.xz  https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz
tar -c $(ISTREAM_HOME)/tools -xf $(ISTREAM_HOME)/tools/ffmpeg-release-arm64-static.tar.xz 
rm $(ISTREAM_HOME)/tools/ffmpeg-release-amd64-static.tar.xz
chown -R $(LOCAL_USERNAME):$(LOCAL_USERNAME) $(ISTREAM_HOME)/tools

#
# sshfs
#
sh mount_fs.sh

#
# deploy project
#
sudo -u $(LOCAL_USERNAME)<<EOF
npm install
EOF
npm install -g ./

#
# create unit
#
sh create_unit.sh