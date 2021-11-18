#! /bin/bash

set -e;
set -u;

WF_NAME=emc-qcmn-flp-local
QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/emc-qcmn-flp.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/emc-qcmn-flp'
QC_CONFIG_PARAM='qc_config_uri'
COMMONARGS="-b --session default"

cd ..

o2-dpl-raw-proxy $COMMONARGS \
  --dataspec 'x:EMC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-dpl-output-proxy $COMMONARGS \
  --dataspec 'x:EMC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  | o2-qc $COMMONARGS --config ${QC_GEN_CONFIG_PATH} --local --host flp \
  --o2-control $WF_NAME

# Add the final QC config file path as a variable in the workflow template
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
# Will work only with GNU sed (Mac uses BSD sed)
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# Find all usages of the QC config path which was used to generate the workflow and replace them with the template variable
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
# Will work only with GNU sed (Mac uses BSD sed)
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*
