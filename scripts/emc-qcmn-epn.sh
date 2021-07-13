#!/usr/bin/env bash

# set -x;
set -e;
set -u;


QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/emc-qcmn-epn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/emc-qcmn-epn'
QC_CONFIG_PARAM='qc_config_uri'

cd ..

WF_NAME=emc-qcmn-epn-remote

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

# add the templated QC config file path
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the QC config path which was used to generate the workflow
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*
