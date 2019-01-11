#!/bin/bash

IF=bridge0

MY_IP=$(
ip addr show "$IF" | \
	grep -o 'inet [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | \
	grep -o [0-9].* | \
	grep 192.168
	)

ssh my-ddns set-dns-value -f config.work.sh gongt-linux A "$MY_IP" 1800


