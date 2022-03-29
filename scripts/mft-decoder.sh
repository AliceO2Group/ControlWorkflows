#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=mft-decoder
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"

cd ../ 
# DPL command to generate the AliECS dump
o2-dpl-raw-proxy -b --session default --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' | o2-itsmft-stf-decoder-workflow -b --runmft --digits --no-clusters --configKeyValues "MFTClustererParam.noiseFilePath=/tmp/_DUMMY_;MFTClustererParam.dictFilePath=/tmp/_DUMMY_" | o2-dpl-output-proxy -b --session default --dataspec 'x:MFT/DIGITS;y:MFT/DIGITSROF;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control $WF_NAME

