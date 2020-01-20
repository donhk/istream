#!/usr/bin/bash
export UNIT_FILE=/etc/systemd/system/istream.service
touch $(UNIT_FILE)
truncate --size 0 $(UNIT_FILE)

cat <<EOF >> $(UNIT_FILE)
[Unit]
Description=istream service
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=$(LOCAL_USERNAME)
ExecStart=istream i

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable istream
systemctl start istream
systemctl status istream