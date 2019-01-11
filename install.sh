#!/bin/bash

FILE=$1

if [ ! -e "$FILE" ]; then
	echo "Usage: $0 service-file.service" >&2
	exit 1
fi

N="$(basename "$FILE")"
cat "$FILE" | sed 's#\[Service]#[Service]\nEnvironment=SCRIPT_ROOT='$(pwd)'#g' > "/usr/lib/systemd/system/$N"
systemctl daemon-reload
systemctl enable --now "$N"

