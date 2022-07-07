#!/usr/bin/env bash

# set -x;
set -e
set -u

source helpers.sh

WF_NAME=mid-full-qcmn-local
QC_GEN_CONFIG_PATH='json://'$(pwd)'/etc/mid-full-qcmn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mid-flp_raw-epn_full-qcmn'
QC_CONFIG_PARAM='qc_config_uri'

cd ../

# DPL command to generate the AliECS dump

o2-dpl-raw-proxy -b --session default --dataspec 'A:MID/RAWDATA;x:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' | o2-dpl-output-proxy --environment "DPL_OUTPUT_PROXY_ORDERED=1" -b --session default --dataspec 'A:MID/RAWDATA;x:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"' | o2-qc -b --config $QC_GEN_CONFIG_PATH --local --host flp --o2-control $WF_NAME

add_config_variable "$QC_FINAL_CONFIG_PATH" "$QC_GEN_CONFIG_PATH" "$QC_CONFIG_PARAM" "$WF_NAME"

WF_NAME=mid-full-qcmn-remote

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

add_config_variable "$QC_FINAL_CONFIG_PATH" "$QC_GEN_CONFIG_PATH" "$QC_CONFIG_PARAM" "$WF_NAME"
