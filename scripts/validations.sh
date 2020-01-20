#!/usr/bin/bash

# checking the env file is properly placed
if [[ -f ".env" ]]; then
    echo "Configuring environment"
else 
    echo "please update and source .env"
    cp $(ISTREAM_HOME)/.env.src $(ISTREAM_HOME)/.env
    cat $(ISTREAM_HOME)/.env
    exit 1;
fi

if  [[ "root" != "$(USER)" ]] ;
then
    echo "This script needs to be run as root"
    exit 1;
fi