#!/bin/bash

#Function Help
help() {
    echo "Usage: ./run.sh -D domain -A ipv4 [-S subdomain]"
    echo ""
    echo "Options:"
    echo "  -D | --domain       Domain name (REQUIRED)"
    echo "  -A | --ipv4      IP ipv4 (REQUIRED)"
    echo "  -AAA | --ipv6       IPv6 address (OPTIONAL)"
    echo "  -S | --subdomain    Subdomain (OPTIONAL)"
    echo "  -h | --help         Show help"
}

#Function ipv4 Validation
valid_ipv4() {
    local ip="$1"

    IFS='.' read -r o1 o2 o3 o4 <<< "$ip"

    if [ -z "$o1" ] || [ -z "$o2" ] || [ -z "$o3" ] || [ -z "$o4" ]; then
        return 1
    fi

    for octet in "$o1" "$o2" "$o3" "$o4"; do
        if ! [[ "$octet" =~ ^[0-9]+$ ]]; then
            return 1
        fi
        if (( octet < 0 || octet > 255 )); then
            return 1
        fi
    done

    return 0
}

#Function ipv6 Validation
valid_ipv6() {
    local ip="$1"

    [[ "$ip" =~ ^[0-9a-fA-F:.]+$ ]] || return 1
    [[ $(grep -o "::" <<< "$ip" | wc -l) -le 1 ]] || return 1

    if [[ "$ip" =~ \. ]]; then
        local ipv4_part="${ip##*:}"
        valid_ipv4 "$ipv4_part" || return 1
    fi

    IFS=':' read -ra blocks <<< "$ip"

    (( ${#blocks[@]} <= 8 )) || return 1

    for block in "${blocks[@]}"; do
        [[ -z "$block" ]] && continue
        [[ "$block" =~ ^[0-9a-fA-F]{1,4}$ ]] || return 1
    done

    return 0
}


while [ $# -gt 0 ]; do
    case "$1" in
        -D|--domain)
            domain="$2"
            shift 2
            ;;
        -S|--subdomain)
            subdomain="$2"
            shift 2
            ;;
        -A|--ipv4)
            ipv4="$2"
            shift 2
            ;;
        -h|--help)
            help
            exit 0
            ;;
        *)
            echo "Invalid option: $1"
            help
            exit 1
            ;;
    esac
done

if [ -z "$domain" ] || [ -z "$ipv4" ]; then
    echo "Error: Missing required parameters: --domain and --ipv4."
    exit 1
fi

if ! [[ "$domain" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Error: Invalid domain format."
    exit 1
fi

if ! valid_ipv4 "$ipv4"; then
    echo "Error: Invalid IPv4 address format"
    exit 1
fi

if [ -n "$ipv6" ]; then
    if ! valid_ipv6 "$ipv6"; then
        echo "Error: Invalid IPv6 address format."
        exit 1
    fi
fi

#Require root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root."
    exit 1
fi

#Start Instalation & Configuration DNS
apt update && apt install -y bind9 bind9utils dnsutils

octet1=$(echo "$ipv4" | cut -d. -f1)
octet2=$(echo "$ipv4" | cut -d. -f2)
octet3=$(echo "$ipv4" | cut -d. -f3)
octet4=$(echo "$ipv4" | cut -d. -f4)

forward_zone="/etc/bind/db.forward"
reverse_zone="/etc/bind/db.reverse"

cp /etc/bind/db.local "$forward_zone"
cp /etc/bind/db.127 "$reverse_zone"

sed -i "s/localhost./$domain./g" "$forward_zone"

#if ipv4
if [ -n "$ipv4" ]; then
    sed -i "s/127.0.0.1/$ipv4/g" "$forward_zone"
else
    sed -i '/IN\s\+A\s\+/d' "$forward_zone"
fi

#if ipv6
if [ -n "$ipv6" ]; then
    sed -i "s/::1/$ipv6/g" "$forward_zone"
else
    sed -i '/IN\s\+AAAA\s\+/d' "$forward_zone"
fi

#if subdomain
if [ -n "$subdomain" ]; then
    [ -n "$ipv4" ] && echo "$subdomain IN A $ipv4" >> "$forward_zone"
    [ -n "$ipv6" ] && echo "$subdomain IN AAAA $ipv6" >> "$forward_zone"
fi

sed -i "s/localhost./$domain./g" "$reverse_zone"
sed -i "s/1.0.0/$octet4/g" "$reverse_zone"

cat <<EOF >> /etc/bind/named.conf.local

zone "$domain" {
    type master;
    file "$forward_zone";
};

zone "$octet3.$octet2.$octet1.in-addr.arpa" {
    type master;
    file "$reverse_zone";
};
EOF

default_dns="8.8.8.8"
# Restart bind9
systemctl restart bind9
printf "nameserver %s\nnameserver %s\n\n" "$ipv4" "$default_dns" > /etc/resolv.conf
echo "[+] DNS Bind9 configured successfully!"
echo "[+] Domain : $domain"
dig $domain
