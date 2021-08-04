#!/usr/bin/env bash

function add_fmq_shmmonitor_role() {
  FILE=$1
  echo "  - name: fairmq-shmmonitor" >> $FILE
  echo "    enabled: \"{{fmq_cleanup_enabled == 'true'}}\"" >> $FILE
  echo "    task:" >> $FILE
  echo "      load: \"fairmq-shmmonitor\"" >> $FILE
  echo "      trigger: DESTROY" >> $FILE
  echo "      timeout: 10s" >> $FILE
  echo "      critical: false" >> $FILE
}

function add_qc_remote_machine_attribute() {
  FILE=$1
  MACHINE=$2
  
  # add the default for QC remote machine
  ESCAPED_QC_REMOTE_MACHINE=$(printf '%s\n' "$MACHINE" | sed -e 's/[\/&]/\\&/g')
  sed -i /defaults:/\ a\\\ \\\ "qc_remote_machine":\ \""${ESCAPED_QC_REMOTE_MACHINE}"\" $FILE


  # add the attribute
  if [ ! -z $(grep "constraints:" "$FILE") ]; then
    # we naively assume that the string is the leftmost level.
    sed -i /constraints:/\ a\\\ \\\ -\ attribute:\ machine_id\\\n\ \ \ \ value:\ "\""{{\ qc_remote_machine\ }}"\"" $FILE
  else
    sed -i /roles:/i\ \ constraints:\\\n\ \ -\ attribute:\ machine_id\\\n\ \ \ \ value:\ "\""{{\ qc_remote_machine\ }}"\"" $FILE
  fi
}
