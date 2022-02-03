#!/bin/bash

set -o errexit
set -o xtrace

GARBD_OPTS=""
SOURCES=""
POD_NAME="local"
WEIGHT=1

function get_sources() {
    CLUSTER_SIZE=$(peer-list -on-start=/usr/bin/get-pxc-state -service=$PXC_SERVICE 2>&1 \
            | grep wsrep_cluster_size \
            | sort \
            | tail -1 \
            | cut -d : -f 12)

     if [[ ${CLUSTER_SIZE:-0} == 0 ]]; then
        echo '[ERROR] Cannot connect to cluster, size is empty or zero'
        exit 1
     fi

    SOURCES=$(peer-list -on-start=/usr/bin/get-pxc-state -service=$PXC_SERVICE 2>&1 \
        | grep wsrep_ready:ON:wsrep_connected:ON:wsrep_local_state_comment:Synced:wsrep_cluster_status:Primary \
        | sort \
        | cut -d : -f 2 \
        | cut -d . -f 1 \
        | xargs -I {} echo {}.$PXC_SERVICE \
        | tr '\n' ',' \
        | sed 's/.$//')
}

function check_ssl() {
    CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    if [ -f /var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt ]; then
        CA=/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
    fi
    SSL_DIR=${SSL_DIR:-/etc/mysql/ssl}
    if [ -f ${SSL_DIR}/ca.crt ]; then
        CA=${SSL_DIR}/ca.crt
    fi
    SSL_INTERNAL_DIR=${SSL_INTERNAL_DIR:-/etc/mysql/ssl-internal}
    if [ -f ${SSL_INTERNAL_DIR}/ca.crt ]; then
        CA=${SSL_INTERNAL_DIR}/ca.crt
    fi

    KEY=${SSL_DIR}/tls.key
    CERT=${SSL_DIR}/tls.crt
    if [ -f ${SSL_INTERNAL_DIR}/tls.key -a -f ${SSL_INTERNAL_DIR}/tls.crt ]; then
        KEY=${SSL_INTERNAL_DIR}/tls.key
        CERT=${SSL_INTERNAL_DIR}/tls.crt
    fi

    if [ -f "$CA" -a -f "$KEY" -a -f "$CERT" ]; then
        GARBD_OPTS="socket.ssl_ca=${CA};socket.ssl_cert=${CERT};socket.ssl_key=${KEY};socket.ssl_cipher=${GARBD_OPTS}"
    fi
}

function start_arbitrator() {
    set +o errexit
    echo '[INFO] garbd was started'
    echo get_sources
    garbd \
        --address "gcomm://$SOURCES" \
        --group "$PXC_SERVICE" \
        --options "pc.weight=${WEIGHT};$GARBD_OPTS"
    EXID_CODE=$?

    exit $EXID_CODE
}

get_sources
check_ssl
start_arbitrator

exit 0
