set -Eeuo pipefail

declare -a PEERS=()
declare -A PEERS_CONFIG WG

function __switchSection() {
	if [[ "$CS" ]]; then # not 1st section
		if [[ "$CS" = "WireGuardPeer" ]]; then
			local PUB=$(echo ${SECTION_INFO[PublicKey]})
			if [[ ! "$PUB" ]]; then
				echo "Some Peer Not Set 'PublicKey'!" >&2
				return
			fi
			local NAME="$(echo ${SECTION_INFO['# Name']})$(echo ${SECTION_INFO['#Name']})"
			if [[ ! "$NAME" ]]; then
				echo "Some Peer Not Set 'Name'." >&2
				NAME="$PUB"
			fi
			PEERS+=("$NAME")
			echo "PEERS+=$NAME"
			for K in "${!SECTION_INFO[@]}"; do
				PEERS_CONFIG["${NAME}.${K}"]="${SECTION_INFO[$K]}"
				echo "PEERS_CONFIG[${NAME}.${K}]=<${SECTION_INFO[$K]}>" >&2
			done
		else
			for K in "${!SECTION_INFO[@]}"; do
				WG[$K]="${SECTION_INFO[$K]}"
				echo "WG[$K]=<${SECTION_INFO[$K]}>" >&2
			done
		fi
	fi
}

function readConfig() {
	echo -ne "\e[2m" >&2
	local p LINE S CS='' K V
	local -A SECTION_INFO=()
	while IFS="" read -r p || [ -n "$p" ]; do
		LINE=$(echo $p)

		if [[ ! "$LINE" ]]; then
			continue
		fi

		if [[ "$LINE" = "[NetDev]" ]]; then
			S="NetDev"
		elif [[ "$LINE" = "[WireGuardPeer]" ]]; then
			S="WireGuardPeer"
		elif [[ "$LINE" = "[WireGuard]" ]]; then
			S="WireGuard"
		else
			K=${LINE%%=*}
			V=${LINE#*=}
			# echo "[${CS}] $K -> $V"
			SECTION_INFO["$(echo $K)"]=$(echo $V)
			continue
		fi

		__switchSection

		SECTION_INFO=()
		CS=$S
	done <"$1"

	__switchSection

	echo -ne "\e[0m" >&2
}

function x() {
	echo "  + $*"
	"$@"
}

NETDEV=80-wg0

echo "======================================"
NETDEV_FILE="/etc/systemd/network/$NETDEV.netdev"

readConfig $NETDEV_FILE

if [[ "${WG[Kind]}" != "wireguard" ]]; then
	echo "network kind <${WG[Kind]}> is not 'wireguard'" >&2
	exit 0
fi

declare -r INTERFACE=${WG['Name']}
declare -r WGTABLE="$(wg show $INTERFACE dump)"

for PEER in "${PEERS[@]}"; do
	echo -e "\e[38;5;14mpeer $PEER\e[0m"

	ENDPOINT=${PEERS_CONFIG["${PEER}.Endpoint"]}
	EP_HOST=${ENDPOINT%%:*}
	EP_PORT=${ENDPOINT#*:}

	if [[ "$(host $EP_HOST)" =~ \.arpa ]]; then
		echo "    using hardcode ip address $EP_HOST."
		continue
	fi

	echo "    using hostname $EP_HOST"

	IP=$(dig +short A $EP_HOST)
	echo "    ip address is $IP"

	PUBLIC_KEY="${PEERS_CONFIG["${PEER}.PublicKey"]}"
	OLD=$( echo "$WGTABLE" | grep "$PUBLIC_KEY" | awk '{print $3}')
	echo "    current target is $OLD"

	if [[ "$OLD" != "$IP:$EP_PORT" ]] ; then
		echo "    target has change!"
		x wg set "$INTERFACE" peer "$PUBLIC_KEY" endpoint "$IP:$EP_PORT"
	fi
done

echo "======================================"
echo "Completed..."
