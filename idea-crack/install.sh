#!/bin/bash

cd $(dirname "$(realpath "${BASH_SOURCE[0]}")")

cat idea-license-server.service | sed "s#BINARY_PATH#$(pwd)#" > /tmp/idea-license-server.service

cp idea-crack.socket /tmp/idea-license-server.service idea-crack.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable idea-crack.socket
systemctl stop idea-crack.service idea-license-server.service
systemctl restart idea-crack.socket

