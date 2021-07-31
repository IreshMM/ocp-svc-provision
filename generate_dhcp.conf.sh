#!/bin/bash
CLUSTER_NAME="$1"

cat > dhcpd.conf <<EOF
  authoritative;
  ddns-update-style interim;
  allow booting;
  allow bootp;
  allow unknown-clients;
  ignore client-updates;
  default-lease-time 14400;
  max-lease-time 14400;

  subnet 192.168.22.0 netmask 255.255.255.0 {
   option routers                  192.168.22.1; # lan
   option subnet-mask              255.255.255.0;
   option domain-name              "ocp.lan";
   option domain-name-servers       192.168.22.1;
   range 192.168.22.80 192.168.22.99;
  }
EOF

# $1 -> Hostname
# $2 -> IP
generate_host_block() {

  MAC=`~/.local/bin/vcd -j vm info "$CLUSTER_NAME" "$1" \
                          | /usr/bin/jq -r '."nic-0".mac'`

  cat >> dhcpd.conf <<EOF
    host $1 {
     hardware ethernet $MAC;
     fixed-address $2;
    }

EOF

}

# Bootstrap node
generate_host_block ocp-bootstrap 192.168.22.200

# Control plane
for instance in {1..3}; do
  generate_host_block "ocp-cp-${instance}" "192.168.22.20${instance}"
done;

# Worker nodes
for instance in {1..2}; do
  generate_host_block "ocp-w-${instance}" "192.168.22.21${instance}"
done;