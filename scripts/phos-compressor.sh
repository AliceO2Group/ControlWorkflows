#!/usr/bin/env bash

# set -x;
set -e;
set -u;

WF_NAME=phos-compressor

cd ..
# DPL command to generate the AliECS dump
o2-dpl-raw-proxy -b --session default --dataspec 'x:PHS/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' | o2-phos-reco-workflow -b --input-type raw --output-type cells --session default --disable-root-output --pedestal off --keepHGLG off --pipeline 'PHOSRawToCellConverterSpec:1' | o2-dpl-output-proxy -b --session default --dataspec 'A:PHS/CELLS/0;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"' --o2-control $WF_NAME

sed -i /defaults:/\ a\\\ \\\ "phos_keep_hglg: off" workflows/${WF_NAME}.yaml
sed -i /defaults:/\ a\\\ \\\ "phos_pedestal: off" workflows/${WF_NAME}.yaml
sed -i /defaults:/\ a\\\ \\\ "phos_fit_method: default" workflows/${WF_NAME}.yaml
sed -i /defaults:/\ a\\\ \\\ "phos_presamples: 0" workflows/${WF_NAME}.yaml

sed -i '/--pedestal/{n;s/.*/    - "{{ phos_pedestal }}"/}' tasks/${WF_NAME}-*
sed -i '/--keepHGLG/{n;s/.*/    - "{{ phos_keep_hglg }}"/}' tasks/${WF_NAME}-*
sed -i '/--fitmethod/{n;s/.*/    - "{{ phos_fit_method }}"/}' tasks/${WF_NAME}-*
sed -i '/--presamples/{n;s/.*/    - "{{ phos_presamples }}"/}' tasks/${WF_NAME}-*

