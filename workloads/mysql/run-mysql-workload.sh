#! /bin/bash

PROJECT=/home/$USER/cs736-project/
NBD=${PROJECT}/nbd-3.3/
WORKLOADS=${PROJECT}/workloads/
HERE=${PROJECT}/workloads/mysql/
STATS=${HERE}/stats.txt
RESULTS=${HERE}/results/
SYSBENCH='sysbench --test=oltp --db-driver=mysql --mysql-user=sbtest --oltp-table-size=5000 --max-requests=1000'

function server_start {
  sudo $NBD/nbd-server -C /etc/nbd-server/config
}

function server_stop {
  sudo killall nbd-server
}

function client_start {
  sudo $NBD/nbd-client -N export localhost /dev/nbd0
  sudo mount /dev/nbd0 /mnt
}

function client_stop {
  sudo umount /mnt
  sudo $NBD/nbd-client -d /dev/nbd0
}

sudo service mysql stop
server_start
client_start
# /mnt/mysql must already have mysql data directory on it
sudo service mysql start
${SYSBENCH} cleanup
${SYSBENCH} prepare
sleep 3
sudo service mysql stop
client_stop
sudo rm -f ${STATS}
client_start
sudo service mysql start
sync
sudo dmesg -C
sync
mkdir -p ${RESULTS}
${SYSBENCH} run > ${RESULTS}/latest-sysbench-output.txt
${SYSBENCH} run >> ${RESULTS}/latest-sysbench-output.txt
${SYSBENCH} run >> ${RESULTS}/latest-sysbench-output.txt
sync
dmesg | grep NBD_SIZE | awk '{print $4}' > ${STATS}
${WORKLOADS}/process-stats.py ${STATS} > ${RESULTS}/latest-stats.txt
sleep 3
sudo service mysql stop
client_stop
server_stop
