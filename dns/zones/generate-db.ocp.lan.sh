#!/bin/bash
NETWORK_IP=$1
MASTER_RANGE="$(eval echo $2)"
WORKER_RANGE="$(eval echo $3)"
BOOTSTRAP_IP=${NETWORK_IP%.*}.200
OCP_SVC_IP=${NETWORK_IP%.*}.8
LOAD_BALANCER_IP=$OCP_SVC_IP
CONF_FILE=db.ocp.lan.test

cat > $CONF_FILE <<EOF
\$TTL    604800
@       IN      SOA     ocp-svc.ocp.lan. contact.ocp.lan (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Minimum
)
        IN      NS      ocp-svc

EOF

cat >> $CONF_FILE <<EOF
ocp-svc.ocp.lan.          IN      A       $OCP_SVC_IP

EOF

cat >> $CONF_FILE <<EOF
; Temp Bootstrap Node
ocp-bootstrap.lab.ocp.lan.        IN      A      $BOOTSTRAP_IP

EOF

echo "; Control Plane Nodes" >> $CONF_FILE
master_number=1
for master_ip in $MASTER_RANGE; do
cat >> $CONF_FILE <<-EOF
ocp-cp-${master_number}.lab.ocp.lan.         IN      A      ${NETWORK_IP%.*}.$master_ip
EOF
    ((master_number++))
done;
echo >> $CONF_FILE

echo "; Worker Nodes" >> $CONF_FILE
worker_number=1
for worker_ip in $WORKER_RANGE; do
cat >> $CONF_FILE <<-EOF
ocp-w-${worker_number}.lab.ocp.lan.         IN      A      ${NETWORK_IP%.*}.$worker_ip
EOF
    ((worker_number++))
done;
echo >> $CONF_FILE

cat >> $CONF_FILE <<EOF
; OpenShift Internal - Load balancer
api.lab.ocp.lan.        IN    A    $LOAD_BALANCER_IP
api-int.lab.ocp.lan.    IN    A    $LOAD_BALANCER_IP
*.apps.lab.ocp.lan.     IN    A    $LOAD_BALANCER_IP
EOF
echo >> $CONF_FILE

echo "; ETCD Cluster" >> $CONF_FILE
master_number=0
for master_ip in $MASTER_RANGE; do
cat >> $CONF_FILE <<-EOF
etcd-${master_number}.lab.ocp.lan.         IN      A      ${NETWORK_IP%.*}.$master_ip
EOF
    ((master_number++))
done;
echo >> $CONF_FILE

echo "; OpenShift Internal SRV records (cluster name = lab)" >> $CONF_FILE
master_number=0
for master_ip in $MASTER_RANGE; do
cat >> $CONF_FILE <<-EOF
_etcd-server-ssl._tcp.lab.ocp.lan.    86400     IN    SRV     0    10    2380    etcd-${master_number}.lab
EOF
    ((master_number++))
done;
echo >> $CONF_FILE

cat >> $CONF_FILE <<EOF
oauth-openshift.apps.lab.ocp.lan.     IN     A     $LOAD_BALANCER_IP
console-openshift-console.apps.lab.ocp.lan.     IN     A     $LOAD_BALANCER_IP
EOF