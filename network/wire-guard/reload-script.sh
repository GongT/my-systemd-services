set -e

NETDEV=30-wg0
NETDEV_FILE="/etc/systemd/network/$NETDEV.netdev"
HOSTNAME=home.gongt.me
RESOLVER=ns.he.net

INTERFACE=$(cat "$NETDEV_FILE" | grep 'Name' | grep -oE '\S+$')
PORT=$(cat "$NETDEV_FILE" | grep 'Endpoint' | grep -oE ':\S+$')
PUBLIC_KEY="$(wg show wg0 | grep 'peer:' | grep -oE '\S+$')"

CURRENT="$(wg show wg0 | grep 'endpoint' | grep -oE '\b([0-9]+\.)+[0-9]+\b')"
echo "Current ip address is: $CURRENT."

echo -n "Using $RESOLVER as resolver: "
RESOLVER_IP=$(nslookup "$RESOLVER" | grep 'Address: ' | grep -oE '\b([0-9]+\.)+[0-9]+\b')
echo "${RESOLVER_IP}."

echo -n "Resolving ip address: "
IP_ADDR="$(nslookup "$HOSTNAME" "$RESOLVER_IP" | grep 'Address: ' | grep -oE '\b([0-9]+\.)+[0-9]+\b')"
echo "$IP_ADDR."

if [ "$CURRENT" = "$IP_ADDR" ] ; then
	echo "IP address is same."
	if echo "$*" | grep -q -- "-f" ; then
		echo "Force run"
	else
		exit 0
	fi
fi

echo "Updating network device config file ($NETDEV_FILE)..."
sed -Ei "s/^Endpoint\s*=\s*.+$/Endpoint = $IP_ADDR$PORT/g" "$NETDEV_FILE"

echo "Set wg0 peer IP address ($PUBLIC_KEY)..."
wg set "$INTERFACE" peer "$PUBLIC_KEY" endpoint "$IP_ADDR$PORT"

echo "Completed..."

