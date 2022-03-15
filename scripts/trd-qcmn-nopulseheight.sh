#!/usr/bin/env bash

#set -x;
set -e;
set -u;

source helpers.sh

QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/trd-full-qcmn-nopulseheight-epn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/trd-full-qcmn-nopulseheight'
QC_CONFIG_PARAM='qc_config_uri'

cd ..

# DPL commands to generate the AliECS dump

# IMPORTANT NOTE ABOUT THE DS POLICY
# The Dispatcher sends data to the Decoder that sends data to QC task. This is different from the normal scheme.
# Thus the datasampling policy is not included in the config file of the task.

WF_NAME=trd-full-qcmn-nopulseheight-epn

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

add_config_variable "$QC_FINAL_CONFIG_PATH" "$QC_GEN_CONFIG_PATH" "$QC_CONFIG_PARAM" "$WF_NAME"

add_fmq_shmmonitor_role workflows/${WF_NAME}.yaml
add_qc_remote_machine_attribute workflows/${WF_NAME}.yaml alio2-cr1-qc05
