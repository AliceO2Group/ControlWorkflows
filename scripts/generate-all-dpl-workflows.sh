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
./cpv-pedestal-calib-qc-expert.sh
./cpv-physics.sh
./cpv-physics-testing.sh
./cpv-physics-qcmn-epn.sh
./cpv-noise-calib-qc.sh
./fdd-qcmn-remote.sh
./fdd-qc-post-processing.sh
./fdd-digits-pipe.sh
./fdd-digits-pipe-ds-qc.sh
./fdd-digits-pipe-ds-qc-raw.sh
./fdd-digits-qc.sh
./ft0-qcmn-remote.sh
./ft0-qc-post-processing.sh
./ft0-qcmn-epn-post-processing.sh
./ft0-digits-pipe.sh
./ft0-digits-pipe-ds-qc.sh
./ft0-digits-pipe-ds-qc-raw.sh
./ft0-decoder-pipe.sh
./ft0-decoder-pipe-ds-qc.sh
./ft0-decoder-pipe-ds-qc-raw.sh
./ft0-digits-qc.sh
./fv0-qcmn-remote.sh
./fv0-qc-post-processing.sh
./fv0-digits-pipe.sh
./fv0-digits-pipe-ds-qc.sh
./fv0-digits-pipe-ds-qc-raw.sh
./fv0-digits-qc.sh
./emc-qc-post-calib.sh
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
./its-qcmn-fee-no-ds.sh
./its-qcmn-cluster-track.sh
./its-qcmn-flp-epn.sh
./its-qcmn-fee-epn.sh
./its-qcmn-flp-epn-no-ds.sh
./its-qcmn-epn.sh
./its-qcmn-full.sh
./its-qcmn-flp-epn-no-ds-nocluster.sh
./its-qcmn-epn-calibration.sh
./mch-qcmn-flp-digits.sh
./mch-qcmn-epn-digits.sh
./mch-qcmn-epn-full.sh
./mch-qcmn-epn-full-track-matching.sh
./mft-decoder.sh
./mft-digits-qc.sh
./mft-full-qcmn.sh
./mft-track-full-qcmn.sh
./mft-noise-qcmn.sh
# ./mft-raw-digits-qc.sh # disabled until the MFT decoder is fixed and we optimize the workflow
./mft-raw-qcmn.sh
./mft-raw-direct-qcmn.sh
./mft-raw-qc.sh
./mft-raw-cluster-qcmn.sh
./mid-raw-decoder.sh
./mid-digits-qcmn.sh
./mid-full-qcmn.sh
./mid-calib-qcmn.sh
./minimal-dpl.sh
./phos-compressor-raw-qc.sh
./phos-compressor-raw-qcmn.sh
./phos-compressor.sh
./phos-compressor-raw-qct3.sh
./phos-compressor-raw-qcmnt3.sh
./phos-compressort3.sh
./phos-raw-clusters.sh
./phos-raw-clusters-epn.sh
./qc-daq.sh
./qcmn-daq.sh
./tof-compressor.sh
./tof-qcmn-compressor.sh
./tof-full-qcmn.sh
./tof-full-qcmn-paranoid.sh
./tof-full-epn-qcmn.sh
./tpc-full-calib-qcmn.sh
./tpc-full-qcmn.sh
./tpc-full-nodummy-qcmn.sh
./tpc-krypton-qcmn.sh
./tpc-idc-sac.sh
./tpc-idc-sac-simple.sh
./tpc-qc-post-processing.sh
./trd-qcmn.sh
./trd-qcmn-nodigits.sh
./trd-qcmn-nopulseheight.sh
./trd-qcmn-norawdatastats.sh
./trd-qcmn-notracklets.sh
./zdc-raw-qc.sh
