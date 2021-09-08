#!/usr/bin/env bash

#set -x;
set -e
set -u

# shellcheck disable=SC1091
source helpers.sh

WF_NAME=mid-raw-decoder

CONFIG_HOME="$PWD/etc"
#TODO: Fnd a more suitable place to store the configuration files
CONFIG_FINAL_DIR="/tmp/mid-workflows"

MID_GEN_FEEID_CONFIG="$CONFIG_HOME/mid_feeId_mapper.txt"
MID_FINAL_FEEID_CONFIG="$CONFIG_FINAL_DIR/feeId_mapper.txt"
MID_PARAM_FEEID_CONFIG="mid_feeid_config_file"

MID_GEN_CRATE_MASKS="$CONFIG_HOME/mid_crate_masks.txt"
# TODO: Uncomment if masks change
# MID_FINAL_CRATE_MASKS="$CONFIG_FINAL_DIR/crate_masks.txt"
MID_FINAL_CRATE_MASKS=""
MID_PARAM_CRATE_MASKS="mid_crate_masks_file"

MID_GEN_ELECTRONICS_DELAY="$CONFIG_HOME/mid_electronics_delay.txt"
MID_FINAL_ELECTRONICS_DELAY="$CONFIG_FINAL_DIR/electronics_delay.txt"
MID_PARAM_ELECTRONICS_DELAY="mid_electronics_delay_file"

ARGS_ALL="-b --session default"

cd ..

# DPL commands to generate the AliECS dump

o2-dpl-raw-proxy ${ARGS_ALL} --dataspec "A:MID/RAWDATA;x:FLP/DISTSUBTIMEFRAME/0" \
    --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-pipe-0,transport=shmem,rateLogging=1"' |
    o2-mid-raw-to-digits-workflow ${ARGS_ALL} --feeId-config-file "$MID_GEN_FEEID_CONFIG" --crate-masks-file "$MID_GEN_CRATE_MASKS" --electronics-delay-file "$MID_GEN_ELECTRONICS_DELAY" |
    o2-dpl-output-proxy -b --session default --dataspec "AD:MID/DATA/0;AR:MID/DATAROF/0;x:FLP/DISTSUBTIMEFRAME/0" --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control "$WF_NAME"

add_config_variable "$MID_FINAL_FEEID_CONFIG" "$MID_GEN_FEEID_CONFIG" "$MID_PARAM_FEEID_CONFIG" "$WF_NAME"

add_config_variable "$MID_FINAL_CRATE_MASKS" "$MID_GEN_CRATE_MASKS" "$MID_PARAM_CRATE_MASKS" "$WF_NAME"

add_config_variable "$MID_FINAL_ELECTRONICS_DELAY" "$MID_GEN_ELECTRONICS_DELAY" "$MID_PARAM_ELECTRONICS_DELAY" "$WF_NAME"

add_fmq_shmmonitor_role workflows/${WF_NAME}.yaml
