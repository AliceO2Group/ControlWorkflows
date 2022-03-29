#!/usr/bin/env bash

function add_fmq_shmmonitor_role() {
  FILE=$1
  echo "  - name: fairmq-shmmonitor" >>$FILE
  echo "    enabled: \"{{fmq_cleanup_enabled == 'true'}}\"" >>$FILE
  echo "    task:" >>$FILE
  echo "      load: \"fairmq-shmmonitor\"" >>$FILE
  echo "      trigger: DESTROY" >>$FILE
  echo "      timeout: 10s" >>$FILE
  echo "      critical: false" >>$FILE
}

function add_qc_remote_machine_attribute() {
  FILE=$1
  MACHINE=$2

  # add the default for QC remote machine
  ESCAPED_QC_REMOTE_MACHINE=$(printf '%s\n' "$MACHINE" | sed -e 's/[\/&]/\\&/g')
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "/defaults:/a\\
  qc_remote_machine: \"${ESCAPED_QC_REMOTE_MACHINE}\"
    " "$FILE"
  else
    sed -i /defaults:/\ a\\\ \\\ "qc_remote_machine":\ \""${ESCAPED_QC_REMOTE_MACHINE}"\" $FILE
  fi

  # add the attribute
  if [ ! -z $(grep "constraints:" "$FILE") ]; then
    # we naively assume that the string is the leftmost level.
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/constraints:/a\\
  - attribute: machine_id\\
    value:\ \"{{\ qc_remote_machine\ }}\"
" $FILE
    else
      sed -i /constraints:/\ a\\\ \\\ -\ attribute:\ machine_id\\\n\ \ \ \ value:\ "\""{{\ qc_remote_machine\ }}"\"" $FILE
    fi
  else
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/roles:/i\\
constraints:\\
  - attribute: machine_id\\
    value:\ \"{{\ qc_remote_machine\ }}\"
" $FILE
    else
      sed -i /roles:/i\ \ constraints:\\\n\ \ -\ attribute:\ machine_id\\\n\ \ \ \ value:\ "\""{{\ qc_remote_machine\ }}"\"" $FILE
    fi
  fi
}

function add_config_variable() {
  FINAL_VARIABLE="$1"
  GEN_VARIABLE="$2"
  PARAM="$3"
  WF_NAME="$4"
export DPL_CONDITION_BACKEND="http://127.0.0.1:8084"

  # add the templated variable
  ESCAPED_FINAL_VARIABLE=$(printf '%s\n' "${FINAL_VARIABLE}" | sed -e 's/[\/&]/\\&/g')
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "/defaults:/a\\
  ${PARAM}: \"${ESCAPED_FINAL_VARIABLE}\"
  " workflows/"${WF_NAME}".yaml
  else
    sed -i /defaults:/\ a\\\ \\\ "${PARAM}":\ \""${ESCAPED_FINAL_VARIABLE}"\" workflows/"${WF_NAME}".yaml
  fi

  # find and replace all usages of the variable which was used to generate the workflow
  ESCAPED_GEN_VARIABLE=$(printf '%s\n' "${GEN_VARIABLE}" | sed -e 's/[]\/$*.^[]/\\&/g')
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/""${ESCAPED_GEN_VARIABLE}""/{{ ""${PARAM}"" }}/g" workflows/"${WF_NAME}".yaml tasks/"${WF_NAME}"-*
  else
    sed -i "s/""${ESCAPED_GEN_VARIABLE}""/{{ ""${PARAM}"" }}/g" workflows/"${WF_NAME}".yaml tasks/"${WF_NAME}"-*
  fi
}
