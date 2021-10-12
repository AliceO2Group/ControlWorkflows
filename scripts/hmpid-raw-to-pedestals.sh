#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=hmpid-raw-to-pedestals

cd ..

# DPL command to generate the AliECS dump
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:HMP/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-hmpid-raw-to-pedestals-workflow \
  | o2-dpl-output-proxy -b --session default \
  --dataspec 'A:HMP/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"' \
  --o2-control $WF_NAME
