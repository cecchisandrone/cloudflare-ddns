#!/bin/bash
# Inspired to https://willwarren.com/2014/07/03/roll-dynamic-dns-service-using-amazon-route53

# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ZONEID=$1
RECORDID=$2
DNS=$3
AUTH_EMAIL=$4
AUTH_KEY=$5

# Get the external IP address from OpenDNS (more reliable than other providers)
IP=`dig +short myip.opendns.com @resolver1.opendns.com`

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

function truncate_log() {

    # Truncate log file
    SIZE=$(wc -l < $LOGFILE)
    echo $SIZE
    if [ "$SIZE" -gt "$LOGFILE_LIMIT" ]; then
        echo "$(tail -$LOGFILE_LIMIT $LOGFILE)" > $LOGFILE
    fi
}

# Get current dir
# (from http://stackoverflow.com/a/246128/920350)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOGFILE="$DIR/cloudflare-ddns.log"
IPFILE="$DIR/cached_ip"
LOGFILE_LIMIT=1000000

echo "$(date): ZONEID: $ZONEID - RECORDID: $RECORDID - DNS: $DNS - AUTH_EMAIL: $AUTH_EMAIL - AUTH_KEY: $AUTH_KEY" >> "$LOGFILE"

if ! valid_ip $IP; then
    echo "$(date): Invalid IP address: $IP" >> "$LOGFILE"
    exit 1
fi

# Check if the IP has changed
if [ ! -f "$IPFILE" ]
    then
    touch "$IPFILE"
fi

if grep -Fxq "$IP" "$IPFILE"; then
    echo "$(date): IP is still $IP. Skipping" >> "$LOGFILE"
    truncate_log
    exit 0
else
    echo "$(date): IP has changed to $IP, updating it on Cloudflare" >> "$LOGFILE"
    curl -sX PUT "https://api.cloudflare.com/client/v4/zones/$ZONEID/dns_records/$RECORDID" -H "X-Auth-Email: $AUTH_EMAIL" -H "X-Auth-Key: $AUTH_KEY" -H "Content-Type: application/json" -o /dev/null \
    --data-binary @- <<EOF
{
  "type":"A",
  "name":"$DNS",
  "content":"$IP",
  "ttl":1,
  "proxied":false
}
EOF
fi

# All Done - cache the IP address for next time
echo "$IP" > "$IPFILE"

truncate_log
