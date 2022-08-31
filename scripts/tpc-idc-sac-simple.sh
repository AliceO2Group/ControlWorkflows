 #!/usr/bin/env bash

# set -x;
set -e;
set -u;

#module load O2PDPSuite

source helpers.sh

WF_NAME=tpc-idc-sac-simple
WF_NAME_A=tpc-idc-simple-a
WF_NAME_C=tpc-idc-simple-c
WF_SAC=tpc-sac

cd ..


export GLOBAL_SHMSIZE=$(( 16 << 30 )) #  GB for the global SHMEM
PROXY_INSPEC="x:TPC/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0"


OUTSPEC_IDC="idc2:TPC/IDCGROUP"
OUTSPEC_IDC_A="idc2:TPC/IDCGROUPA"
OUTSPEC_IDC_C="idc2:TPC/IDCGROUPC"
OUTSPEC="xout:TPC/RAWDATA;ddout:FLP/DISTSUBTIMEFRAME/0"

# TODO: Adjust path and check this ends up properly in the script
CRU_GEN_CONFIG_PATH='//'`pwd`'/scripts/etc/getCRUs.sh'
CRU_GEN_CONFIG_PATH_A=11,13
CRU_GEN_CONFIG_PATH_C=211,213
CRU_FINAL_CONFIG_PATH='$(/home/tpc/IDCs/FLP/getCRUs.sh)'
CRU_CONFIG_PARAM='cru_config_uri'

CRUS='\"$(/home/tpc/IDCs/FLP/getCRUs.sh)\"'
CRUS_LOCAL='$('`pwd`"/etc/getCRU.sh"

# TODO: Adjust merger and port, if the port is change this also must be done
#       in the merger script


MERGER=epn024-ib
MERGER_A=epn024-ib
MERGER_C=epn024-ib
PORT=47734

nTFs=1000
ccdb="ccdb-test.cern.ch:8080"
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"
export DPL_CONDITION_QUERY_RATE="${GEN_TOPO_EPN_CCDB_QUERY_RATE:--1}"
DPL_PROCESSING_CONFIG_KEY_VALUES="NameConf.mCCDBServer=http://127.0.0.1:8084;"

ARGS_ALL="-b --session default "

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-idc-to-vector $ARGS_ALL \
  --crus ${CRU_GEN_CONFIG_PATH_A} \
  --severity error \
  --infologger-severity error \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  --pedestal-url http://o2-ccdb.internal \
  | o2-tpc-idc-flp $ARGS_ALL \
  --crus ${CRU_GEN_CONFIG_PATH_A} \
  --severity warning \
  --infologger-severity warning \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  --lanes 1 \
  --disableIDC0CCDB true \
  | o2-dpl-output-proxy $ARGS_ALL \
   --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
   --dataspec "${OUTSPEC};${OUTSPEC_IDC_A}" \
   --environment "DPL_OUTPUT_PROXY_ORDERED=1" \
   --o2-control $WF_NAME_A

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-idc-to-vector $ARGS_ALL \
  --crus ${CRU_GEN_CONFIG_PATH_C} \
  --severity error \
  --infologger-severity error \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  --pedestal-url http://o2-ccdb.internal \
  | o2-tpc-idc-flp $ARGS_ALL \
  --crus ${CRU_GEN_CONFIG_PATH_C} \
  --severity warning \
  --infologger-severity warning \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  --lanes 1 \
  --disableIDC0CCDB true \
  | o2-dpl-output-proxy $ARGS_ALL \
   --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
   --dataspec "${OUTSPEC};${OUTSPEC_IDC_C}" \
   --environment "DPL_OUTPUT_PROXY_ORDERED=1" \
   --o2-control $WF_NAME_C

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec "$PROXY_INSPEC" \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc://tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-tpc-sac-processing --severity warning --condition-tf-per-query -1 \
  | o2-tpc-sac-distribute --timeframes ${nTFs} --output-lanes 1 \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  | o2-tpc-sac-factorize --timeframes ${nTFs} --nthreads-SAC-factorization 4 --input-lanes 1 \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  | o2-tpc-idc-ft-aggregator --rangeIDC 200 --nFourierCoeff 40 --process-SACs true --inputLanes 1 \
  --configKeyValues "${DPL_PROCESSING_CONFIG_KEY_VALUES};keyval.output_dir=/dev/null" \
  | o2-calibration-ccdb-populator-workflow --ccdb-path ${ccdb} -b \
  | o2-dpl-output-proxy $ARGS_ALL \
   --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
   --dataspec "${OUTSPEC}" \
   --environment "DPL_OUTPUT_PROXY_ORDERED=1" \
   --o2-control $WF_SAC


# add the templated CRU config file path
ESCAPED_CRU_FINAL_CONFIG_PATH=$(printf '%s\n' "$CRU_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
sed -i /defaults:/\ a\\\ \\\ "${CRU_CONFIG_PARAM}":\ "${ESCAPED_CRU_FINAL_CONFIG_PATH}" workflows/${WF_NAME_A}.yaml
sed -i /defaults:/\ a\\\ \\\ "${CRU_CONFIG_PARAM}":\ "${ESCAPED_CRU_FINAL_CONFIG_PATH}" workflows/${WF_NAME_C}.yaml

# find and replace all usages of the CRU config path which was used to generate the workflow
ESCAPED_CRU_GEN_CONFIG_PATH=$(printf '%s\n' "$CRU_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
ESCAPED_CRU_GEN_CONFIG_PATH_A=$(printf '%s\n' "$CRU_GEN_CONFIG_PATH_A" | sed -e 's/[]\/$*.^[]/\\&/g');
ESCAPED_CRU_GEN_CONFIG_PATH_C=$(printf '%s\n' "$CRU_GEN_CONFIG_PATH_C" | sed -e 's/[]\/$*.^[]/\\&/g');
sed -i "s/""${ESCAPED_CRU_GEN_CONFIG_PATH_A}""/{{ ""${CRU_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME_A}.yaml tasks/${WF_NAME_A}-*
sed -i "s/""${ESCAPED_CRU_GEN_CONFIG_PATH_C}""/{{ ""${CRU_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME_C}.yaml tasks/${WF_NAME_C}-*
sed -i "s/'{{ cru_config_uri }}'/{{ cru_config_uri }}/g" tasks/${WF_NAME_A}-*
sed -i "s/'{{ cru_config_uri }}'/{{ cru_config_uri }}/g" tasks/${WF_NAME_C}-*


OUTSPEC_IDC="idc2:TPC/IDCGROUP"
OUTSPEC_IDC_A="idc2:TPC/IDCGROUPA"
OUTSPEC_IDC_C="idc2:TPC/IDCGROUPC"


sed -i "s/ZYX/{{ detector }}/g" workflows/${WF_NAME_A}.yaml tasks/${WF_NAME_A}-*
sed -i "s/ZYX/{{ detector }}/g" workflows/${WF_NAME_C}.yaml tasks/${WF_NAME_C}-*
sed -i "s/ZYX/{{ detector }}/g" workflows/${WF_SAC}.yaml tasks/${WF_SAC}-*

#sed -i "s/alice-ccdb.cern.ch/127.0.0.1:8084/g" workflows/${WF_SAC}.yaml tasks/${WF_SAC}-*



sed -i /defaults:/\ a\\\ \\\ "merger_node_a":\ "${MERGER_A}" workflows/${WF_NAME_A}.yaml
sed -i /defaults:/\ a\\\ \\\ "merger_node_c":\ "${MERGER_C}" workflows/${WF_NAME_C}.yaml

sed -i /defaults:/\ a\\\ \\\ "merger_port":\ "${PORT}" workflows/${WF_NAME_A}.yaml
sed -i /defaults:/\ a\\\ \\\ "merger_port":\ "${PORT}" workflows/${WF_NAME_C}.yaml


aside=" it == 'alio2-cr1-flp001'"
cside=" it == 'alio2-cr1-flp073'"

for ((i = 2 ; i <= 9 ; i++)); do
  aside+=" || it == 'alio2-cr1-flp00${i}' "
done
for ((i = 10 ; i <= 72 ; i++)); do
  aside+=" || it == 'alio2-cr1-flp0${i}' "
done
for ((i = 74 ; i <= 99 ; i++)); do
  cside+=" || it == 'alio2-cr1-flp0${i}' "
done
for ((i = 100 ; i <= 144 ; i++)); do
  cside+=" || it == 'alio2-cr1-flp${i}' "
done

echo "name: tpc-calib-simple-full-split" > workflows/${WF_NAME}-full-split.yaml
echo "roles:" >> workflows/${WF_NAME}-full-split.yaml
echo "  - name: ${WF_NAME_A}" >> workflows/${WF_NAME}-full-split.yaml
echo "    enabled: \"{{ $aside }}\"" >> workflows/${WF_NAME}-full-split.yaml
echo "    include: ${WF_NAME_A}" >> workflows/${WF_NAME}-full-split.yaml
echo "  - name: ${WF_NAME_C}" >> workflows/${WF_NAME}-full-split.yaml
echo "    enabled: \"{{ $cside }}\"" >> workflows/${WF_NAME}-full-split.yaml
echo "    include: ${WF_NAME_C}" >> workflows/${WF_NAME}-full-split.yaml
echo "  - name: ${WF_SAC}" >> workflows/${WF_NAME}-full-split.yaml
echo "    enabled: \"{{ it == 'alio2-cr1-flp145' }}\"" >> workflows/${WF_NAME}-full-split.yaml
echo "    include: ${WF_SAC}" >> workflows/${WF_NAME}-full-split.yaml


