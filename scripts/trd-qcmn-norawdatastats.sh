#!/usr/bin/env bash

#set -x;
set -e;
set -u;

source helpers.sh

QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/trd-full-qcmn-norawdatastats-epn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/trd-full-qcmn-norawdatastats'
QC_CONFIG_PARAM='qc_config_uri'

cd ..

# DPL commands to generate the AliECS dump

# IMPORTANT NOTE ABOUT THE DS POLICY
# The Dispatcher sends data to the Decoder that sends data to QC task. This is different from the normal scheme.
# Thus the datasampling policy is not included in the config file of the task.

WF_NAME=trd-full-qcmn-norawdatastats-epn
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"
DPL_PROCESSING_CONFIG_KEY_VALUES="NameConf.mCCDBServer=http://127.0.0.1:8084;"

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

add_config_variable "$QC_FINAL_CONFIG_PATH" "$QC_GEN_CONFIG_PATH" "$QC_CONFIG_PARAM" "$WF_NAME"

