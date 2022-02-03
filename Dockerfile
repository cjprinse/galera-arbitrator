FROM percona/percona-xtradb-cluster-operator:1.9.0-pxc8.0-backup

COPY arbitrator.sh /usr/bin/
