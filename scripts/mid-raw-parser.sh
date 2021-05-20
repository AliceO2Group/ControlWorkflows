#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=mid-raw-parser

cd ..
# DPL command to generate the AliECS dump
o2-dpl-raw-proxy -b --session default --dataspec 'A:MID/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --channel-config name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=5 | o2-dpl-raw-parser -b --session default --input-spec A:MID/RAWDATA --log-level 0 | o2-dpl-output-proxy -b --session default --dataspec 'A:MID/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control $WF_NAME

