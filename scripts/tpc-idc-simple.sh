 #!/usr/bin/env bash

# set -x;
set -e;
set -u;

#module load O2PDPSuite

source helpers.sh

WF_NAME=tpc-idc-simple

cd ..


export GLOBAL_SHMSIZE=$(( 16 << 30 )) #  GB for the global SHMEM
PROXY_INSPEC="x:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"

OUTSPEC_IDC="idc2:TPC/IDCGROUPA"
OUTSPEC="xout:TPC/RAWDATA;ddout:FLP/DISTSUBTIMEFRAME/0"

# TODO: Adjust path and check this ends up properly in the script
CRU_GEN_CONFIG_PATH='//'`pwd`'/scripts/etc/getCRUs.sh'
CRU_FINAL_CONFIG_PATH='$(/home/tpc/IDCs/FLP/getCRUs.sh)'
CRU_CONFIG_PARAM='cru_config_uri'

CRUS='\"$(/home/tpc/IDCs/FLP/getCRUs.sh)\"'
CRUS_LOCAL='$('`pwd`"/etc/getCRU.sh"

# TODO: Adjust merger and port, if the port is change this also must be done
#       in the merger script


MERGER=epn024-ib
PORT=47734

ARGS_ALL="-b --session default "

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-idc-to-vector $ARGS_ALL \
  --crus ${CRU_GEN_CONFIG_PATH} \
  --severity error \
  --infologger-severity error \
  --configKeyValues "keyval.output_dir=/dev/null" \
  --pedestal-url http://o2-ccdb.internal \
  | o2-tpc-idc-flp $ARGS_ALL \
  --propagateIDCs true \
  --crus ${CRU_GEN_CONFIG_PATH} \
  --severity warning \
  --infologger-severity warning \
  --configKeyValues "keyval.output_dir=/dev/null" \
  --lanes 1 \
  --disableIDC0CCDB true \
  | o2-dpl-output-proxy $ARGS_ALL \
   --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
   --dataspec "${OUTSPEC};${OUTSPEC_IDC}" \
   --o2-control $WF_NAME

# add the templated CRU config file path
ESCAPED_CRU_FINAL_CONFIG_PATH=$(printf '%s\n' "$CRU_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${CRU_CONFIG_PARAM}":\ "${ESCAPED_CRU_FINAL_CONFIG_PATH}" workflows/${WF_NAME}.yaml

# find and replace all usages of the CRU config path which was used to generate the workflow
ESCAPED_CRU_GEN_CONFIG_PATH=$(printf '%s\n' "$CRU_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_CRU_GEN_CONFIG_PATH}""/{{ ""${CRU_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*
sed -i "s/'{{ cru_config_uri }}'/{{ cru_config_uri }}/g" tasks/${WF_NAME}-*

sed -i "s/ZYX/{{ detector }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*

sed -i /defaults:/\ a\\\ \\\ "merger_node":\ "${MERGER}" workflows/${WF_NAME}.yaml

sed -i /defaults:/\ a\\\ \\\ "merger_port":\ "${PORT}" workflows/${WF_NAME}.yaml


echo "name: tpc-calib-full" > workflows/${WF_NAME}-full.yaml
echo "roles:" >> workflows/${WF_NAME}-full.yaml
echo "  - name: tpc-idc-simple" >> workflows/${WF_NAME}-full.yaml
echo "    enabled: \"{{ it != 'alio2-cr1-flp145' }}\"" >> workflows/${WF_NAME}-full.yaml
echo "    include: tpc-idc-simple" >> workflows/${WF_NAME}-full.yaml
echo "  - name: tpc-sac" >> workflows/${WF_NAME}-full.yaml
echo "    enabled: \"{{ it == 'alio2-cr1-flp145' }}\"" >> workflows/${WF_NAME}-full.yaml
echo "    include: minimal-dpl" >> workflows/${WF_NAME}-full.yaml


