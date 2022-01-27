#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=tpc-idc

cd ..

# DPL command to generate the AliECS dump
#o2-dpl-raw-proxy -b --session default --dataspec 'x:ZYX/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
#| o2-dpl-output-proxy -b --session default --dataspec 'x:ZYX/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control $WF_NAME

export GLOBAL_SHMSIZE=$(( 16 << 30 )) #  GB for the global SHMEM
#PROXY_INSPEC="A:TPC/RAWDATA"
PROXY_INSPEC="A:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"

#OUTSPEC='downstream:TPC/1DIDC;downstream:TPC/IDCGROUP'
OUTSPEC='downstream:TPC/1DIDC;downstream:TPC/IDCGROUP'
# TODO: Adjust path to pedestal file
pedestalFile="/home/tpc/IDCs/FLP/Pedestals.root"

# TODO: Adjust path and check this ends up properly in the script
#CRUS='$(/home/tpc/IDCs/FLP/getCRUs.sh)'
CRUS="11,13"
# TODO: Adjust merger and port, if the port is change this also must be done
#       in the merger script
MERGER=epn102-ib
PORT=30453

ARGS_ALL="-b --session default --shm-segment-size $GLOBAL_SHMSIZE"

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-idc-to-vector $ARGS_ALL \
  --crus ${CRUS} \
  --pedestal-file $pedestalFile \
  --severity info \
  | o2-tpc-idc-flp $ARGS_ALL \
  --propagateIDCs true \
  --crus ${CRUS} \
  --severity info \
  | o2-dpl-output-proxy $ARGS_ALL \
  --channel-config "name=downstream,method=connect,address=tcp://${MERGER}:${PORT},type=push,transport=zeromq" \
  --dataspec "${OUTSPEC}" \
  --o2-control $WF_NAME

#  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://@tf-builder-pipe-0,transport=shmem,rateLogging=1"' \


sed -i "s/ZYX/{{ detector }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*



