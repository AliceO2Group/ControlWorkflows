#!/usr/bin/env bash

# set -x;
set -e
set -u

# This takes all the workflows found in the "scripts" directory and creates corresponding files in the "jit" directory.

# Checks if current pwd matches the location of this script, exits if it is not
function check_pwd() {
  DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
  if [[ $DIR != $PWD ]]; then
    echo 'Please execute this script while being in its directory'
    exit 1
  fi
}
check_pwd

if ! command -v jq &> /dev/null
  then
  echo "jq could not be found, please install it"
  exit
fi

if ! command -v yq &> /dev/null
  then
  echo "yq could not be found, please install it"
  exit
fi

for workflow_template_path in ../workflows/*.yaml; do
  echo 'Processing workflow_template_path '$workflow_template_path
  
  DPL_COMMAND=$(yq -r .vars.dpl_command ${workflow_template_path})

  if [[ -z "${DPL_COMMAND}" || "${DPL_COMMAND}" == null ]]; then
    echo 'Skipping, not a DPL workflow'
    continue
  fi

  WF_NAME=$(basename ${workflow_template_path} | sed 's/\.yaml//g')
  if [[ -z "${WF_NAME}" ]]; then
    echo 'Workflow name for the file '${workflow_template_path}' turned out to be empty, skipping.'
    continue
  fi

  QC_CONFIG_URI=$(yq -r .defaults.qc_config_uri ${workflow_template_path})
  if [[ -n "${QC_CONFIG_URI}" ]]; then
    # ESCAPED_DPL_COMMAND=$(printf '%s\n' "$DPL_COMMAND" | sed -e 's/[]\/$*.^[]/\\&/g')
    ESCAPED_QC_CONFIG_URI=$(printf '%s\n' "$QC_CONFIG_URI" | sed -e 's/[]\/$*.^[]/\\&/g')
    DPL_COMMAND=$(printf '%s\n' "${DPL_COMMAND}" | sed -e "s/{{ qc_config_uri }}/""${ESCAPED_QC_CONFIG_URI}""/g")
  fi
  
  DS_CONFIG_URI=$(yq -r .defaults.ds_config_uri ${workflow_template_path})
  if [[ -n "${DS_CONFIG_URI}" ]]; then
    ESCAPED_DS_CONFIG_URI=$(printf '%s\n' "$DS_CONFIG_URI" | sed -e 's/[]\/$*.^[]/\\&/g')
    DPL_COMMAND=$(printf '%s\n' "${DPL_COMMAND}" | sed -e "s/{{ ds_config_uri }}/""${ESCAPED_DS_CONFIG_URI}""/g")
  fi
  
  echo ${DPL_COMMAND}

  echo ${DPL_COMMAND} > ../jit/${WF_NAME}
done
