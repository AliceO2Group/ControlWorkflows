#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=mft-test2-full-qcmn-local
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"
export DPL_CONDITION_QUERY_RATE="${GEN_TOPO_EPN_CCDB_QUERY_RATE:--1}"
DPL_PROCESSING_CONFIG_KEY_VALUES="NameConf.mCCDBServer=http://127.0.0.1:8084;"
QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/mft-full-qcmn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mft-full-qcmn-{{ it }}'
QC_CONFIG_PARAM='qc_config_uri'

DS_GEN_CONFIG_PATH='json://'`pwd`'/etc/mft-full-digits-sampling.json'
DS_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mft-full-digits-sampling'
DS_CONFIG_PARAM='ds_config_uri'

source helpers.sh

cd ../

# DPL command to generate the AliECS dump
o2-dpl-raw-proxy -b --session default --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-itsmft-stf-decoder-workflow -b --runmft --digits --no-clusters --dataspec "TF:MFT/RAWDATA" --ignore-dist-stf --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES}" --pipeline 'mft-stf-decoder:3' \
  | o2-dpl-output-proxy --environment "DPL_OUTPUT_PROXY_ORDERED=1" -b --session default --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  | o2-qc --config ${QC_GEN_CONFIG_PATH} -b --local --host flp --o2-control $WF_NAME

# add the templated QC config file path
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the QC config path which was used to generate the workflow
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

# add the templated DS config file path
ESCAPED_DS_FINAL_CONFIG_PATH=$(printf '%s\n' "$DS_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${DS_CONFIG_PARAM}":\ \""${ESCAPED_DS_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the DS config path which was used to generate the workflow
ESCAPED_DS_GEN_CONFIG_PATH=$(printf '%s\n' "$DS_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_DS_GEN_CONFIG_PATH}""/{{ ""${DS_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*


QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mft-full-qcmn'
WF_NAME=mft-test2-full-qcmn-remote
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"
export DPL_CONDITION_QUERY_RATE="${GEN_TOPO_EPN_CCDB_QUERY_RATE:--1}"
DPL_PROCESSING_CONFIG_KEY_VALUES="NameConf.mCCDBServer=http://127.0.0.1:8084;"

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

# add the templated QC config file path
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the QC config path which was used to generate the workflow
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

