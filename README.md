# istream
ONVIF RSTP client to backup streams into remote server

## Installation instructions
- Run the install script from the root folder 
    
    `./scripts/centos7_install.sh`
    `./scripts/raspbian_install.sh`

After the install is done you will have
- A command called `istream`
- A new systemd unit for controlling the stream using

        sudo systemctl stop istream
        sudo systemctl start istream