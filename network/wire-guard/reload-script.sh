set -e
CACHE=/etc/wireguard/last-ip.txt
echo -n "resolving ip address..."
IP_ADDR=$(nslookup home.gongt.me ns.he.net  | grep "Address: " | grep -oP "[\.\d]+")
echo $IP_ADDR
if [ -e "$CACHE" ] && [ "$(< "$CACHE")" = "$IP_ADDR" ] ; then
	echo "IP address is same."
	exit
fi
systemctl restart systemd-networkd.service
echo "$IP_ADDR" > "$CACHE"
