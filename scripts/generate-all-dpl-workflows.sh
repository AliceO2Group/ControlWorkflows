#!/usr/bin/env bash

#set -x;
set -e
set -u

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
./cpv-compressor.sh
./cpv-qc-compressor.sh
./cpv-pedestal-calib-qc.sh
./cpv-physics.sh
./cpv-physics-testing.sh
./cpv-physics-qcmn-epn.sh
./fdd-qcmn-remote.sh
./fdd-digits-qc-full-nocalib.sh
./fdd-digits-qc-full-nocalib-raw.sh
./fdd-digits-pipe.sh
./fdd-digits-qc-ds-pipe.sh
./fdd-digits-qc-ds.sh
./fdd-digits-qc.sh
./fdd-digits.sh
./ft0-qcmn-remote.sh
./ft0-digits-qc-full.sh
./ft0-digits-qc-full-raw.sh
./ft0-digits-qc-full-nocalib.sh
./ft0-digits-qc-full-nocalib-raw.sh
./ft0-digits-pipe.sh
./ft0-digits-qc-ds-pipe.sh
./ft0-digits-qc-ds-pipe-raw.sh
./ft0-digits-qc-ds.sh
./ft0-digits-qc-postproc-ds-pipe.sh
./ft0-digits-qc-postproc-ds.sh
./ft0-digits-qc.sh
./ft0-digits.sh
./fv0-qcmn-remote.sh
./fv0-digits-qc-full.sh
./fv0-digits-qc-full-raw.sh
./fv0-digits-qc-full-nocalib.sh
./fv0-digits-qc-full-nocalib-raw.sh
./fv0-digits-pipe.sh
./fv0-digits-qc-ds-pipe.sh
./fv0-digits-qc-ds-pipe-raw.sh
./fv0-digits-qc-ds.sh
./fv0-digits-qc-postproc-ds-pipe.sh
./fv0-digits-qc-postproc-ds.sh
./fv0-digits-qc.sh
./fv0-digits.sh
./emc-qcmn-local-flp.sh
./emc-qcmn-remote-flp.sh
./emc-qcmn-remote-flpepn.sh
./emc-qcmn-epn.sh
./emc-qcmn-epnall.sh
./hmpid-raw-qcmn.sh
./hmpid-raw-qc.sh
./hmpid-raw-to-pedestals.sh
./its-qc-fhr-fee.sh
./its-qcmn-fhr-fee.sh
./its-qc-fhr-fee-no-ds.sh
./its-qcmn-fhr-fee-no-ds.sh
./its-qcmn-fhr-fee-no-ds-entire.sh
./its-qcmn-cluster-track.sh
./its-qcmn-flp-epn.sh
./its-qcmn-flp-epn-no-ds.sh
./its-qcmn-flp-epn-no-ds-nocluster.sh
./mch-qcmn-flp-digits.sh
./mch-qcmn-epn-digits.sh
./mft-decoder.sh
./mft-digits-qc.sh
./mft-full-qcmn.sh
# ./mft-raw-digits-qc.sh # disabled until the MFT decoder is fixed and we optimize the workflow
./mft-raw-qcmn.sh
./mft-raw-direct-qcmn.sh
./mft-raw-qc.sh
./mft-raw-cluster-qcmn.sh
./mid-raw-decoder.sh
./mid-qcmn-epn-digits.sh
./minimal-dpl.sh
./phos-compressor-raw-qc.sh
./phos-compressor-raw-qcmn.sh
./phos-compressor.sh
./phos-compressor-raw-qct3.sh
./phos-compressor-raw-qcmnt3.sh
./phos-compressort3.sh
./phos-raw-clusters.sh
./qc-daq.sh
./qcmn-daq.sh
./tof-compressor.sh
./tof-qcmn-compressor.sh
./tof-full-qcmn.sh
./tpc-full-calib-qcmn.sh
./tpc-full-qcmn.sh
./tpc-full-nodummy-qcmn.sh
./tpc-full-nodummy-qcmn-pp.sh
./tpc-krypton-qcmn.sh
./tpc-qc-post-trending.sh
./tpc-qc-post-calib.sh
./tpc-qc-post-processing.sh

