#!/usr/bin/env bash

# set -x;
set -e
set -u

source helpers.sh

WF_NAME=mid-full-qcmn-remote
QC_GEN_CONFIG_PATH='json://'$(pwd)'/etc/mid-full-qcmn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mid-full-qcmn'
QC_CONFIG_PARAM='qc_config_uri'

cd ../

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

add_config_variable "$QC_FINAL_CONFIG_PATH" "$QC_GEN_CONFIG_PATH" "$QC_CONFIG_PARAM" "$WF_NAME"

WF_NAME=${WF_NAME//"mid-full"/"mid-full-noraw"}
QC_GEN_CONFIG_PATH=${QC_GEN_CONFIG_PATH//"mid-full"/"mid-full-noraw"}

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

add_config_variable "$QC_FINAL_CONFIG_PATH" "$QC_GEN_CONFIG_PATH" "$QC_CONFIG_PARAM" "$WF_NAME"
