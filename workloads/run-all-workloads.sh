#! /bin/bash

PROJECT=/home/${USER}/cs736-project/
NBD=${PROJECT}/nbd-3.3/
WORKLOADS=${PROJECT}/workloads/
STATS=${WORKLOADS}/nbd-stats.txt
RESULTS=${WORKLOADS}/results/

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

iterations=1000

server_start
for writesize in 8 64 512 4096
do
  for syncprob in 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0
  do
    for behavior in sequential random
    do
      sudo rm -f ${STATS}
      client_start
      rm -f /mnt/test.txt
      dd if=/dev/zero of=/mnt/test.txt bs=4096 count=1024
      sync
      sudo dmesg -C
      sync
      ${WORKLOADS}/workloads.py -s ${syncprob} -b 1024 -f /mnt/test.txt -w ${writesize} -i ${iterations} -t ${behavior}
      sync
      dmesg | grep NBD_SIZE | awk '{print $4}' > ${STATS}
      mkdir -p ${RESULTS}
      ${WORKLOADS}/process-stats.py ${STATS} > ${RESULTS}/${behavior}-${writesize}-${syncprob}.txt
      client_stop
      sync
    done
  done
done
server_stop
