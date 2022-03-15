  #!/usr/bin/env bash

# set -x;
set -e;
set -u;

module load O2PDPSuite

source helpers.sh

WF_NAME=tpc-idc

cd ..


export GLOBAL_SHMSIZE=$(( 16 << 30 )) #  GB for the global SHMEM
PROXY_INSPEC="x:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"

OUTSPEC_IDC="idc1:TPC/1DIDC;idc2:TPC/IDCGROUP"
OUTSPEC="xout:TPC/RAWDATA;ddout:FLP/DISTSUBTIMEFRAME/0"
# TODO: Adjust path to pedestal file
pedestalFile="/home/tpc/IDCs/FLP/Pedestals.root"

CRUIDS="11,13"

# TODO: Adjust path and check this ends up properly in the script
CRU_GEN_CONFIG_PATH='//'`pwd`'/scripts/etc/getCRUs.sh'
CRU_FINAL_CONFIG_PATH='$(/home/tpc/IDCs/FLP/getCRUs.sh)'
CRU_CONFIG_PARAM='cru_config_uri'

CRUS='\"$(/home/tpc/IDCs/FLP/getCRUs.sh)\"'
CRUS_LOCAL='$('`pwd`"/etc/getCRU.sh"
#CRUS='$(/tmp/getCRUs.sh)'
# TODO: Adjust merger and port, if the port is change this also must be done
#       in the merger script
MERGER=alio2-cr1-qts01.cern.ch
#MERGER=epn028-ib
#MERGER=alio2-cr1-flp145
PORT=47734

ARGS_ALL="-b --session default "
#--shm-segment-size $GLOBAL_SHMSIZE"

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-idc-to-vector $ARGS_ALL \
  --crus ${CRU_GEN_CONFIG_PATH} \
  --pedestal-file $pedestalFile \
  --severity info \
  --configKeyValues "keyval.output_dir=/dev/null" \
  | o2-tpc-idc-flp $ARGS_ALL \
  --propagateIDCs true \
  --crus ${CRU_GEN_CONFIG_PATH} \
  --severity info \
  --configKeyValues "keyval.output_dir=/dev/null" \
  --lanes 1 \
  | o2-dpl-output-proxy $ARGS_ALL \
   --proxy-name tpc-idc-merger-proxy \
   --proxy-channel-name tpc-idc-merger-proxy \
   --labels "tpc-idc-merger-proxy:ecs-preserve-raw-channels" \
   --output-proxy-method connect \
   --tpc-idc-merger-proxy '--channel-config "name=tpc-idc-merger-proxy,method=connect,address=tcp://{{ merger_node }}:{{ merger_port }},type=push,transport=zeromq" ' \
   --dataspec "${OUTSPEC_IDC}" \
  | o2-dpl-output-proxy $ARGS_ALL \
   --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
   --dataspec "${OUTSPEC}" \
   --o2-control $WF_NAME

#   --default-port 47734 \
#   --tpc-idc-merger-proxy '--channel-config "name=tpc-idc-merger-proxy,method=connect,type=push,transport=zeromq" ' \


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


ORIGINAL_STRING="tpc-idc-merger-proxy-{{ it }}"
REPLACE_STRING="tpc-idc-merger-proxy"

#sed -i "s/""${ORIGINAL_STRING}""/""${REPLACE_STRING}""/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*


export GLOBAL_SHMSIZE=$(( 128 << 30 )) #  GB for the gl

WF_NAME=tpc-idc-merger

lanes=5
nTFs=1000

firstCRU=11
lastCRU=13
sCRUs=""
loc="A:TPC/IDCGROUP/"
loc1D="A:TPC/1DIDC/"

for ((i = ${firstCRU} ; i <= ${lastCRU} ; i=i+2)); do
  [ -n "${sCRUs}" ] && sCRUs+=";"
  sCRUs+="${loc}$((${i}<<7));${loc1D}$((${i}<<7))"
done


sCRUs="dd:TPC/IDCGROUP;dd:TPC/1DIDC"

echo "CRUs: ${sCRUs}"

CCDB="http://ccdb-test.cern.ch:8080"

crus="$firstCRU-$lastCRU"
crus="11,13"



CRU_GEN_MERGER_ID='{CRUS}'
CRU_FINAL_MERGER_ID='0-355'
CRU_MERGER_ID='cru_merger_ids'

ARGS_ALL="-b --session default --shm-segment-size $GLOBAL_SHMSIZE"

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec ${sCRUs} \
  --severity info \
  --labels "tpc-idc-merger-proxy:ecs-preserve-raw-channels" \
  --proxy-name tpc-idc-merger-proxy \
  --channel-config "name=tpc-idc-merger-proxy,type=pull,method=bind,address=tcp://*:{{ merger_port }},rateLogging=1,transport=zeromq" \
  | o2-tpc-idc-distribute $ARGS_ALL \
  --crus ${CRU_GEN_MERGER_ID} \
  --firstTF  1 \
  --timeframes ${nTFs} \
  --output-lanes ${lanes} \
  --configKeyValues 'keyval.output_dir=/dev/null'  \
  | o2-tpc-idc-ft-aggregator $ARGS_ALL \
  --crus ${CRU_GEN_MERGER_ID} \
  --rangeIDC 200 \
  --nFourierCoeff 40 \
  --timeframes ${nTFs} \
  --ccdb-uri "${CCDB}" \
  --configKeyValues 'keyval.output_dir=/dev/null'  \
  --severity info \
  | o2-tpc-idc-factorize $ARGS_ALL \
  --crus ${CRU_GEN_MERGER_ID} \
  --timeframes ${nTFs} \
  --input-lanes ${lanes} \
  --configFile "" \
  --compression 0 \
  --ccdb-uri "${CCDB}" \
  --configKeyValues 'TPCIDCGroupParam.groupPadsSectorEdges=32211;keyval.output_dir=/dev/null'  \
  --groupIDCs true \
  --nthreads-grouping 4 \
  --groupPads "5,6,7,8,4,5,6,8,10,13" \
  --groupRows "2,2,2,3,3,3,2,2,2,2" \
  --severity info \
  --o2-control $WF_NAME




# replace {{ it  }} in in proxy name in taks and workflow

# add the templated CRU config file path
ESCAPED_CRU_FINAL_MERGER_ID=$(printf '%s\n' "$CRU_FINAL_MERGER_ID" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${CRU_MERGER_ID}":\ "${ESCAPED_CRU_FINAL_MERGER_ID}" workflows/${WF_NAME}.yaml

# find and replace all usages of the CRU config path which was used to generate the workflow

ESCAPED_CRU_GEN_MERGER_ID=$(printf '%s\n' "$CRU_GEN_MERGER_ID" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_CRU_GEN_MERGER_ID}""/{{ ""${CRU_MERGER_ID}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*


sed -i /defaults:/\ a\\\ \\\ "merger_port":\ "${PORT}" workflows/${WF_NAME}.yaml


ORIGINAL_STRING="tpc-idc-merger-proxy-{{ it }}"
REPLACE_STRING="tpc-idc-merger-proxy"

sed -i "s/""${ORIGINAL_STRING}""/""${REPLACE_STRING}""/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*


add_qc_remote_machine_attribute workflows/${WF_NAME}.yaml alio2-cr1-qts01

