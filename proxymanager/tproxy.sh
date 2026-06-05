#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-}"
INSTANCE="${TPROXY_INSTANCE:-}"

# ==================== Requirements Check ====================
for cmd in ip nft; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "FATAL: command not found: $cmd" >&2
        exit 1
    }
done

[ -n "$INSTANCE" ] || {
    echo "FATAL: TPROXY_INSTANCE not set" >&2
    exit 1
}

# 配置文件路径：匹配 tproxy@<INSTANCE> 读取 <INSTANCE>_tproxy.conf
CONFIG_FILE="/etc/pxm/${INSTANCE}_tproxy.conf"

[ -f "$CONFIG_FILE" ] || {
    echo "FATAL: config file not found: $CONFIG_FILE" >&2
    echo "HINT: Please create it, e.g., /etc/pxm/${INSTANCE}_tproxy.conf" >&2
    exit 1
}

# shellcheck source=/dev/null
source "$CONFIG_FILE"

# ==================== Variable Validation ====================
require_vars=(
    TPROXY_PORT
    FWMARK
    TABLE_ID
    NFTABLES_TABLE
)

for v in "${require_vars[@]}"; do
    if [ -z "${!v:-}" ]; then
        echo "FATAL: variable $v is not set in $CONFIG_FILE" >&2
        exit 1
    fi
done

# 检查 EXCLUDE_GID 或 ROUTING_MARK 至少存在一个
if [ -z "${EXCLUDE_GID:-}" ] && [ -z "${ROUTING_MARK:-}" ]; then
    echo "FATAL: Either EXCLUDE_GID or ROUTING_MARK must be set in $CONFIG_FILE" >&2
    exit 1
fi

# ==================== Bypass Rule Logic ====================
# 当两者都存在时，默认优先使用 EXCLUDE_GID
if [ -n "${EXCLUDE_GID:-}" ]; then
    BYPASS_RULE="meta skgid $EXCLUDE_GID return"
else
    BYPASS_RULE="meta mark $ROUTING_MARK return"
fi

# ==================== Network Intelligence ====================
# Get all global IPv4 addresses
get_local_cidrs() {
    ip -4 addr show scope global | awk '/inet /{print $2}'
}

LOCAL_CIDRS="$(get_local_cidrs || true)"

if [ -z "$LOCAL_CIDRS" ]; then
    echo "WARN: No local IPv4 CIDRs detected. Bypassing might be incomplete."
fi

# Reserved IPv4 Ranges for Bypassing
BYPASS_IPS=(
    "127.0.0.0/8"
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "169.254.0.0/16"
    "224.0.0.0/4"
    "240.0.0.0/4"
)

# ==================== Routing Logic ====================
setup_routes() {
    ip rule del fwmark "$FWMARK" table "$TABLE_ID" 2>/dev/null || true
    ip rule add fwmark "$FWMARK" table "$TABLE_ID"

    ip route flush table "$TABLE_ID" 2>/dev/null || true
    ip route add local 0.0.0.0/0 dev lo table "$TABLE_ID"
}

remove_routes() {
    ip rule del fwmark "$FWMARK" table "$TABLE_ID" 2>/dev/null || true
    ip route flush table "$TABLE_ID" 2>/dev/null || true
}

# ==================== nftables Orchestration ====================
setup_nftables() {
    nft delete table ip "$NFTABLES_TABLE" 2>/dev/null || true
    nft add table ip "$NFTABLES_TABLE"

    # Define bypass set
    nft add set ip "$NFTABLES_TABLE" BYPASS_LIST \
        '{ type ipv4_addr; flags interval; }'

    # Add reserved ranges
    nft add element ip "$NFTABLES_TABLE" BYPASS_LIST \
        "{ $(IFS=,; echo "${BYPASS_IPS[*]}") }"

    # Add dynamic local CIDRs to bypass list (skip those already covered by reserved ranges)
    if [ -n "$LOCAL_CIDRS" ]; then
        for cidr in $LOCAL_CIDRS; do
            # Skip if already covered by reserved ranges (e.g. 192.168.x.x within 192.168.0.0/16)
            local_ip="${cidr%%/*}"
            if echo "$local_ip" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)'; then
                continue
            fi
            nft add element ip "$NFTABLES_TABLE" BYPASS_LIST "{ $cidr }"
        done
    fi

    # -------- TPROXY_PREROUTING --------
    nft add chain ip "$NFTABLES_TABLE" PREROUTING \
        '{ type filter hook prerouting priority mangle; policy accept; }'

    # Exclude proxy self-traffic (Dynamic Rule)
    nft add rule ip "$NFTABLES_TABLE" PREROUTING $BYPASS_RULE
    
    # Allow local DNS/Services on bypass list, except for specific overrides if needed
    nft add rule ip "$NFTABLES_TABLE" PREROUTING ip daddr @BYPASS_LIST udp dport != 53 return
    nft add rule ip "$NFTABLES_TABLE" PREROUTING ip daddr @BYPASS_LIST tcp dport != 53 return

    nft add rule ip "$NFTABLES_TABLE" PREROUTING \
        ip protocol { tcp, udp } \
        meta mark set "$FWMARK" \
        tproxy to 127.0.0.1:"$TPROXY_PORT"

    # -------- TPROXY_OUTPUT (Local Traffic) --------
    nft add chain ip "$NFTABLES_TABLE" OUTPUT \
        '{ type route hook output priority mangle; policy accept; }'

    # Exclude proxy self-traffic (Dynamic Rule)
    nft add rule ip "$NFTABLES_TABLE" OUTPUT $BYPASS_RULE

    # Skip bypass list
    nft add rule ip "$NFTABLES_TABLE" OUTPUT ip daddr @BYPASS_LIST udp dport != 53 return
    nft add rule ip "$NFTABLES_TABLE" OUTPUT ip daddr @BYPASS_LIST tcp dport != 53 return

    # Mark local traffic to be routed via policy table
    nft add rule ip "$NFTABLES_TABLE" OUTPUT ip protocol { tcp, udp } meta mark set "$FWMARK"
}

remove_nftables() {
    nft delete table ip "$NFTABLES_TABLE" 2>/dev/null || true
}

# ==================== Main ====================
case "$ACTION" in
    start)
        remove_nftables
        remove_routes
        setup_routes
        setup_nftables
        echo "TProxy configuration completed successfully for instance: $INSTANCE"
        ;;
    stop)
        remove_nftables
        remove_routes
        echo "TProxy configuration stopped for instance: $INSTANCE"
        ;;
    *)
        echo "Usage: $0 {start|stop}" >&2
        exit 1
        ;;
esac