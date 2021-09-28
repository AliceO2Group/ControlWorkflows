#!/usr/bin/env bash

#set -x;
set -e;
set -u;

source helpers.sh

WF_NAME=mch-qcmn-epn-digits-local

QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/mch-qcmn-epn-digits.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mch-qcmn-epn-digits'
QC_CONFIG_PARAM='qc_config_uri'

DS_GEN_CONFIG_PATH='json://'`pwd`'/etc/mch-digits-datasampling.json'
DS_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/mch-digits-datasampling'
DS_CONFIG_PARAM='ds_config_uri'

ARGS_ALL="-b --session default"
PROXY_INSPEC="A:MCH/RAWDATA"
DECOD_INSPEC="TF:MCH/RAWDATA_SAMPLED"

CONFIG_HOME=`pwd`'etc'
#CONFIG_HOME="$(pwd)"

cd ..

# DPL commands to generate the AliECS dump

# IMPORTANT NOTE ABOUT THE DS POLICY
# The Dispatcher sends data to the Decoder that sends data to QC task. This is different from the normal scheme.
# Thus the datasampling policy is not included in the config file of the task.

o2-dpl-raw-proxy ${ARGS_ALL} --dataspec "${PROXY_INSPEC};x:FLP/DISTSUBTIMEFRAME/0" \
    --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://@tf-builder-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-dpl-output-proxy ${ARGS_ALL} --dataspec "${PROXY_INSPEC};x:FLP/DISTSUBTIMEFRAME/0" --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' --o2-control $WF_NAME

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



WF_NAME=mch-qcmn-epn-digits-remote

o2-qc --config $QC_GEN_CONFIG_PATH --remote -b --o2-control $WF_NAME

# add the templated QC config file path
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# find and replace all usages of the QC config path which was used to generate the workflow
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

add_fmq_shmmonitor_role workflows/${WF_NAME}.yaml
add_qc_remote_machine_attribute workflows/${WF_NAME}.yaml alio2-cr1-qc01
