#!/bin/bash
NETWORK_IP=$1
SUBNET_SUFFIX=$2
CONF_FILE=named.conf.test

cat > $CONF_FILE <<EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

EOF

cat >> $CONF_FILE <<EOF
options {
	listen-on port 53 { 127.0.0.1; $NETWORK_IP; };
#	listen-on-v6 port 53 { ::1; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query     { localhost; $NETWORK_IP/$SUBNET_SUFFIX; };

	/*
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable
	   recursion.
	 - If your recursive DNS server has a public IP address, you MUST enable access
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface
	*/
	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;

	# Using Google DNS
	forwarders {
                8.8.8.8;
                8.8.4.4;
        };

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.root.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

EOF

reverse_subnet() {
    SUBNET=${1%.*}
    R_SUBNET=''
    for segment in $(echo $SUBNET | tr "." " "); do
        R_SUBNET=$segment.$R_SUBNET
    done;
    R_SUBNET=${R_SUBNET%?}
    echo $R_SUBNET
}

R_SUBNET=`reverse_subnet $NETWORK_IP`

cat >> $CONF_FILE <<EOF
# Include ocp zones

zone "ocp.lan" {
    type master;
    file "/etc/named/zones/db.ocp.lan"; # zone file path
};

zone "$R_SUBNET.in-addr.arpa" {
    type master;
    file "/etc/named/zones/db.reverse";  # $NETWORK_IP/$SUBNET_SUFFIX subnet
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF