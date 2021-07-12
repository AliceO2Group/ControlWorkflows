#!/usr/bin/env bash

#set -x;
set -e;
set -u;

# This will run all the scripts for regenerating the WFTs&TTs.
# Please note that:
# - you have to enter the O2 environment to run these scripts
# - the scripts use GNU sed. Not expected to work on Mac
# - when regenerating the templates, use the closest sw versions to the target versions
# - do not name workflows so one name includes other. e.g. 'its-qc-one' and 'its-qc'.
#   otherwise the sed commands for 'its-qc's TTs might affect 'its-qc-one' as well.

# Checks if current pwd matches the location of this script, exits if it is not
function check_pwd() {
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
  if [[ $DIR != $PWD ]]; then
    echo 'Please execute this script while being in its directory'
    exit 1
  fi
}

check_pwd

# ./datasampling-02.sh # this is a test workflow, no need for it in production
./ft0-digits-qc.sh
./hmpid-raw-qcmn.sh
./hmpid-raw-qc.sh
./its-qc-fhr-fee.sh
./its-qcmn-fhr-fee.sh
./mch-qcmn-digits.sh
./mft-decoder.sh
./mft-digits-qc.sh
# ./mft-raw-digits-qc.sh # disabled until the MFT decoder is fixed and we optimize the workflow
./mft-raw-qcmn.sh
./mft-raw-qc.sh
./mid-raw-parser.sh
./minimal-dpl.sh
./phos-compressor-raw-qc.sh
./phos-compressor-raw-qcmn.sh
./phos-compressor.sh
./phos-compressor-raw-qct3.sh
./phos-compressor-raw-qcmnt3.sh
./phos-compressort3.sh
./qc-daq.sh
./qcmn-daq.sh
./tof-compressor.sh
./tof-qcmn-compressor.sh


