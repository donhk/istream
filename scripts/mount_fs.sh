#!/usr/bin/bash
# sshfs
export UID=`id -u $(LOCAL_USERNAME)`
export GID=`id -g $(LOCAL_USERNAME)`
export OPTIONS="allow_other,default_permissions,reconnect,nonempty,uid=$(UID),gid=$(GID)"
export PREFIX=
if  [[ "$(LOCAL_SERVER_IDENTITY)" != "" ]] ;
then
    OPTIONS="$(OPTIONS),IdentityFile=$(LOCAL_SERVER_IDENTITY)"
else
    PREFIX="sshpass -p $(REMOTE_SERVER_PASS)"
fi
# make sure it is not being used
fusermount -u $(LOCAL_SERVER_DIRECTORY)
$(PREFIX) sshfs $(REMOTE_SERVER_USER)@$(REMOTE_SERVER_ADDRES):$(REMOTE_SERVER_DIRECTORY) $(LOCAL_SERVER_DIRECTORY) -o $(OPTIONS)
