#!/bin/sh

# set val
PORT=${PORT:-8080}
XPORT=${XPORT:-700}
AUUID=${AUUID:-5194845a-cacf-4515-8ea5-fa13a91b1026}
CADDYIndexPage=${CADDYIndexPage:-https://github.com/AYJCSGM/mikutap/archive/master.zip}

# template file
cat >Caddyfile.temp <<EOF
:\$PORT
root * www
file_server browse
basicauth /\$AUUID/* {
        \$AUUID \$UUID_HASH
}
route /\$AUUID-vmess {
        reverse_proxy 127.0.0.1:\$XPORT1
}
route /\$AUUID-vless {
        reverse_proxy 127.0.0.1:\$XPORT2
}
route /\$AUUID-trojan {
        reverse_proxy 127.0.0.1:\$XPORT3
}
EOF

cat >config.json <<EOF
{
    "log": {"disabled": false,"level": "info","timestamp": true},
    "dns": {
        "servers": [
            {"tag": "system","address": "local","address_strategy": "prefer_ipv4","strategy": "prefer_ipv4","detour": "direct"},
            {"tag": "google-udp","address": "8.8.8.8","address_strategy": "prefer_ipv4","strategy": "prefer_ipv4","detour": "direct"}
        ],
        "strategy": "prefer_ipv4",
        "disable_cache": false,
        "disable_expire": false
    },
    "inbounds": [
        {
            "type": "vmess","tag": "vmess-in","listen": "127.0.0.1","listen_port": \$XPORT1,"domain_strategy": "prefer_ipv4",
            "sniff": false,"tcp_fast_open": false,"proxy_protocol": false,"sniff_override_destination": false,
            "users": [{"name": "wuzhu","uuid": "\$AUUID","alterId": 0}],
            "transport": {"type": "ws","path": "/\$AUUID-vmess","headers": {},"max_early_data": 0,"early_data_header_name": "Sec-WebSocket-Protocol"}
        },
        {
            "type": "trojan","tag": "trojan-in","listen": "127.0.0.1","listen_port": \$XPORT3,"domain_strategy": "prefer_ipv4",
            "sniff": false,"tcp_fast_open": false,"proxy_protocol": false,"sniff_override_destination": false,
            "users": [{"name": "wuzhu","password": "\$AUUID"}],
            "transport": {"type": "ws","path": "/\$AUUID-trojan","headers": {},"max_early_data": 0,"early_data_header_name": "Sec-WebSocket-Protocol"}
        }
    ],
    "outbounds": [
        {"type": "direct","tag": "direct"},
        {"type": "block","tag": "block"},
        {"type": "dns","tag": "dns-out"}
    ],
    "route": {
        "rules": [
            {"protocol": "dns","outbound": "dns-out"},
            {"inbound": ["vmess-in","trojan-in"],"geosite": ["category-ads-all"],"outbound": "block"}
        ],
        "geoip": {"path": "geoip.db","download_url": "https://github.com/SagerNet/sing-geoip/releases/latest/download/geoip.db","download_detour": "direct"},
        "geosite": {"path": "geosite.db","download_url": "https://github.com/SagerNet/sing-geosite/releases/latest/download/geosite.db","download_detour": "direct"},
        "final": "direct",
        "auto_detect_interface": true
    }
}
EOF

# download execution
SING_VERSION=$(curl -sS "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | grep tag_name | cut -f4 -d '"' | cut -dv -f2)
CADDY_VERSION=$(curl -sS "https://api.github.com/repos/caddyserver/caddy/releases/latest" | grep tag_name | cut -f4 -d '"' | cut -dv -f2)
SING_VERSION=${SING_VERSION:-1.2.6}
CADDY_VERSION=${CADDY_VERSION:-2.6.4}
wget -q "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_amd64.tar.gz" -O caddy-linux-amd64.tar.gz
wget -q "https://github.com/SagerNet/sing-box/releases/download/v${SING_VERSION}/sing-box-${SING_VERSION}-linux-amd64.tar.gz" -O sing-box-linux-amd64.tar.gz
tar -xvzf sing-box-linux-amd64.tar.gz && mv sing-box-${SING_VERSION}-linux-amd64/sing-box . && rm -rf sing-box-${SING_VERSION}-linux-amd64 sing-box-linux-amd64.tar.gz
tar -xvzf caddy-linux-amd64.tar.gz && rm -rf caddy-linux-amd64.tar.gz
chmod +x caddy sing-box

# set caddy
rm -rf www && mkdir -p www
echo -e "User-agent: *\nDisallow: /" >www/robots.txt
wget -q $CADDYIndexPage -O www/index.html && unzip -qo www/index.html -d www/ && mv www/*/* www/

# set config file
UUID_HASH=$(./caddy hash-password --plaintext $AUUID)
cat ./Caddyfile.temp | sed -e "s/\$PORT/$PORT/g" -e "s/\$XPORT/$XPORT/g" -e "s/\$AUUID/$AUUID/g" -e "s#\$UUID_HASH#$UUID_HASH#g" >Caddyfile
cat ./config.json | sed -e "s/\$XPORT/$XPORT/g" -e "s/\$AUUID/$AUUID/g" >sing.json
rm -rf Caddyfile.temp config.json

# start cmd
./sing-box run -c sing.json >sing.log 2>&1 &
./caddy run --config Caddyfile --adapter caddyfile
