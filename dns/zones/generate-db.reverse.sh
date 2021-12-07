#!/bin/bash
CONF_FILE=db.reverse.test
LOAD_BALANCER_IP_SUFFIX=8
BOOTSTRAP_IP_SUFFIX=200
MASTER_RANGE="$(eval echo $1)"
WORKER_RANGE="$(eval echo $2)"

cat > $CONF_FILE <<EOF
\$TTL    604800
@       IN      SOA     ocp-svc.ocp.lan. contact.ocp.lan (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Minimum
)

EOF

cat >> $CONF_FILE <<EOF
  IN      NS      ocp-svc.ocp.lan.
EOF

cat >> $CONF_FILE <<EOF
$LOAD_BALANCER_IP_SUFFIX      IN    PTR    ocp-svc.ocp.lan.
$LOAD_BALANCER_IP_SUFFIX      IN    PTR    api.lab.ocp.lan.
$LOAD_BALANCER_IP_SUFFIX      IN    PTR    api-int.lab.ocp.lan.
;
EOF

cat >> $CONF_FILE <<EOF
$BOOTSTRAP_IP_SUFFIX    IN    PTR    ocp-bootstrap.lab.ocp.lan.
;
EOF

master_number=1
for master_ip in $MASTER_RANGE; do
cat >> $CONF_FILE <<-EOF
$master_ip    IN    PTR    ocp-cp-${master_number}.lab.ocp.lan.
EOF
    ((master_number++))
done;
echo ";" >> $CONF_FILE


worker_number=1
for worker_ip in $WORKER_RANGE; do
cat >> $CONF_FILE <<-EOF
$worker_ip    IN    PTR    ocp-w-${worker_number}.lab.ocp.lan.
EOF
    ((worker_number++))
done;
echo >> $CONF_FILE