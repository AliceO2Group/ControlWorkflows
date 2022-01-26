#!/usr/bin/env bash

# set -x;
set -e;
set -u;

QC_GEN_CONFIG_PATH='json://'`pwd`'/etc/tpc-full-qcmn.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/tpc-full-qcmn'
QC_CONFIG_PARAM='qc_config_uri'

source helpers.sh

cd ../

WF_NAME=tpc-idc-merger

export DISPLAY=0
export GLOBAL_SHMSIZE=$(( 128 << 30 )) #  GB for the global SHMEM

lanes=2
nTFs=2

firstCRU=0
lastCRU=359
sCRUs=""
loc="A:TPC/IDCGROUP/"
loc1D="A:TPC/1DIDC/"
MERGER=epn160-ib
PORT=30453

for ((i = 0 ; i <= ${lastCRU} ; i++)); do
  [ -n "${sCRUs}" ] && sCRUs+=";"
  sCRUs+="${loc}$((${i}<<7));${loc1D}$((${i}<<7))"
done

echo "CRUs: ${sCRUs}"

CCDB="http://ccdb-test.cern.ch:8080"

crus="$firstCRU-$lastCRU"
# crus="0-1"
ARGS_ALL="-b --session default --shm-segment-size $GLOBAL_SHMSIZE"

o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec ${sCRUs} \
  --channel-config "name=readout-proxy,type=pull,method=bind,address=tcp://*:${PORT},rateLogging=1,transport=zeromq" \
  | o2-tpc-idc-distribute $ARGS_ALL \
  --crus=${crus} \
  --timeframes ${nTFs} \
  --output-lanes ${lanes} \
  | o2-tpc-idc-factorize $ARGS_ALL \
  --crus ${crus} \
  --timeframes ${nTFs} \
  --input-lanes ${lanes} \
  --configFile "" \
  --compression 0 \
  --ccdb-uri "${CCDB}" \
  --configKeyValues 'TPCIDCGroupParam.groupPadsSectorEdges=32211'  \
  --groupIDCs true \
  --nthreads-grouping 4 \
  --groupPads "5,6,7,8,4,5,6,8,10,13" \
  --groupRows "2,2,2,3,3,3,2,2,2,2" \
  | o2-tpc-idc-ft-aggregator $ARGS_ALL \
  --crus ${crus} \
  --rangeIDC 200 \
  --nFourierCoeff 40 \
  --timeframes ${nTFs} \
  --ccdb-uri "${CCDB}" \
  --o2-control $WF_NAME

# add the templated QC config file path

add_qc_remote_machine_attribute workflows/${WF_NAME}.yaml alio2-cr1-qts01

