# istream
ONVIF RSTP client to backup streams into remote server

## Installation instructions
Run the install script from the root folder 

    cp .env.src .env


Fill up the `.env` file with the information and run

    sudo ./scripts/centos7_install.sh
    sudo ./scripts/raspbian_install.sh

After the install is done you will have
- A command called `istream`
- A new systemd unit for controlling the stream using

        sudo systemctl start ${local-mount-dir}.mount
        sudo systemctl start istream.service

- for debugging purposes you can run `istream -h` from which each part of the code can be tested separated

### TODOs
- Add module for offline recording and then sync up onto remote server
- Add quality service process to control main process
