#!/usr/bin/env bash

#set -x;
set -e
set -u

# shellcheck disable=SC1091
source helpers.sh

WF_NAME=mid-raw-decoder
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"
DPL_PROCESSING_CONFIG_KEY_VALUES="NameConf.mCCDBServer=http://127.0.0.1:8084;"

ARGS_ALL="-b --session default"

cd ..

# DPL commands to generate the AliECS dump

o2-dpl-raw-proxy ${ARGS_ALL} --dataspec "A:MID/RAWDATA;x:FLP/DISTSUBTIMEFRAME/0" \
    --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-pipe-0,transport=shmem,rateLogging=1"' |
    o2-mid-raw-to-digits-workflow ${ARGS_ALL} --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES}"|
    o2-dpl-output-proxy -b --session default --dataspec "AD:MID/DATA/0;AR:MID/DATAROF/0;x:FLP/DISTSUBTIMEFRAME/0" --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control "$WF_NAME"

add_fmq_shmmonitor_role workflows/${WF_NAME}.yaml
