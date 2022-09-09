#!/usr/bin/env bash

# set -x;
set -e;
set -u;

QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/tpc-full-nodummy-postprocessing-qcmn-v3.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/tpc-full-nodummy-postprocessing-qcmn-v3'
QC_CONFIG_PARAM='qc_config_uri'

source helpers.sh

cd ../

WF_NAME=tpc-full-nodummy-qcmn-pp-remote-v3

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

# add the templated QC config file path
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the QC config path which was used to generate the workflow
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

sed -i "s/shm_segment_size: \([0-9]\+\)/shm_segment_size: 120000000000/g" workflows/${WF_NAME}.yaml


