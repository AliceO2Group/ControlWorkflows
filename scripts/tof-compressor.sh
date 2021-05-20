#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=tof-compressor

cd ..

# DPL command to generate the AliECS dump
o2-dpl-raw-proxy -b --session default --dataspec 'x0:TOF/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' | o2-tof-compressor -b --session default --pipeline tof-compressor-0:6 --tof-compressor-rdh-version 6 --tof-compressor-config x:TOF/RAWDATA | o2-dpl-output-proxy -b --session default --dataspec 'A:TOF/CRAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"' --o2-control $WF_NAME

