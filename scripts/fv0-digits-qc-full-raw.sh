#!/usr/bin/env bash
#set -x; # debug mode
set -e; # exit on error
set -u; # exit on undefined variable

# Variables
WF_NAME=fv0-digits-qc-full-raw
QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/fv0-digits-qc-full.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/fv0-digits-qc-full-{{ it }}'
QC_CONFIG_PARAM='qc_config_uri'

DS_GEN_CONFIG_PATH='json://'`pwd`'/etc/fv0-digits-datasampling.json'
DS_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/fv0-digits-datasampling-{{ it }}'
DS_CONFIG_PARAM='ds_config_uri'
NTF_TO_STORE=10000
N_PIPELINES=1
cd ..

# Generate the AliECS workflow and task templates
o2-dpl-raw-proxy -b --session default \
  --dataspec 'rawdata:FV0/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' --pipeline  readout-proxy:$N_PIPELINES \
  | o2-fv0-flp-dpl-workflow -b --session default --output-dir=/tmp --nevents ${NTF_TO_STORE} --pipeline  fv0-datareader-dpl:$N_PIPELINES \
  | o2-datasampling-standalone -b --session default --config ${DS_GEN_CONFIG_PATH} \
  | o2-calibration-fv0-tf-processor -b --session default \
  | o2-calibration-fv0-channel-offset-calibration -b --session default \
  | o2-calibration-ccdb-populator-workflow -b --session default --ccdb-path=http://ccdb-test.cern.ch:8080 \
  | o2-dpl-output-proxy -b --session default --dataspec 'rawdata:FV0/RAWDATA;digits:FV0/DIGITSBC/0;channels:FV0/DIGITSCH/0;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  | o2-qc --config ${QC_GEN_CONFIG_PATH} -b \
  --o2-control $WF_NAME
# Add the final QC config file path as a variable in the workflow template
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
# Will work only with GNU sed (Mac uses BSD sed)
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml
# Find all usages of the QC config path which was used to generate the workflow and replace them with the template variable
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
# Will work only with GNU sed (Mac uses BSD sed)
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

# Add the final QC config file path as a variable in the workflow template
ESCAPED_DS_FINAL_CONFIG_PATH=$(printf '%s\n' "$DS_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
# Will work only with GNU sed (Mac uses BSD sed)
sed -i /defaults:/\ a\\\ \\\ "${DS_CONFIG_PARAM}":\ \""${ESCAPED_DS_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml
# Find all usages of the QC config path which was used to generate the workflow and replace them with the template variable
ESCAPED_DS_GEN_CONFIG_PATH=$(printf '%s\n' "$DS_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
# Will work only with GNU sed (Mac uses BSD sed)
sed -i "s/""${ESCAPED_DS_GEN_CONFIG_PATH}""/{{ ""${DS_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*
