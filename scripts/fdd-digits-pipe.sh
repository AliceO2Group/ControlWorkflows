#!/usr/bin/env bash
#set -x; # debug mode
set -e; # exit on error
set -u; # exit on undefined variable

# Variables
WF_NAME=fdd-digits-pipe
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"
DPL_PROCESSING_CONFIG_KEY_VALUES="NameConf.mCCDBServer=http://127.0.0.1:8084;"
N_PIPELINES=10
cd ..

# Generate the AliECS workflow and task templates
o2-dpl-raw-proxy -b --session default \
  --dataspec 'A1:FDD/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-fdd-flp-dpl-workflow -b --session default --disable-root-output --pipeline  fdd-datareader-dpl:$N_PIPELINES --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES}" \
  | o2-dpl-output-proxy --environment "DPL_OUTPUT_PROXY_ORDERED=1" -b --session default --dataspec 'digits:FDD/DIGITSBC/0;channels:FDD/DIGITSCH/0;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  --o2-control $WF_NAME
