# FLP Suite Workflow Configuration
The [`ControlWorkflows`](https://github.com/AliceO2Group/ControlWorkflows) repository hosts the configuration tree for AliECS workflow templates (WFT) and task templates (TT).

Available workflow templates:

* `qc-postprocessing` - QualityControl post-processing workflow
* `readout-dataflow` - Main FLP workflow
* `readout-qc` - QualityControl workflow with Readout as source
* `readout-stfb-qc` - QualityControl workflow with StfBuilder as source


## Notes on input data types

This is mostly relevant to `coconut` users and users who edit or produce their own WFTs and TTs.

All AliECS variables are strings. Some workflow templates can choose to treat a string variable as a JSON payload, with built in functions such as `ToJson`/`FromJson`, but they are always provided as strings by the user, and stored as strings in the key-value map.

Boolean values are also stored as strings, i.e. `"true"` and `"false"`. This is because they can be read in as template expressions, i.e. strings, which are then processed into boolean values during workflow loading.

## Common workflow variables

All variables except **`hosts`** are optional.

| Variable | Description | Example | Default |
| :--- | :--- | :--- | :--- |
| `hosts` | JSON-formatted list of hosts to control the scale of certain workflows | `["myhost1","myhost2"]` | `[]` |
| `readout_cfg_uri` | URI of a Readout configuration payload | `consul-ini://{{ consul_endpoint }}/o2/components/readout/ANY/any/readout-standalone-{{ task_hostname }}` | depends on WFT |
| `user` | Name of the Linux user that should run all tasks | `root` | `flp` |


## `readout-dataflow` workflow variables

All variables are optional.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `roc_ctp_emulator_enabled` | If true, `roc-ctp-emulator` will run during `START` to get data from CRU without LTU | `false` |
| `roc_trigger_mode` | Trigger mode for `roc-ctp-emulator` (only if `roc_ctp_emulator_enabled` is `true` ) | `continuous` |
| `roc_ctp_emulator_endpoints` | List of CRU endpoints to emulate trigger (only if `roc_ctp_emulator_enabled` is `true` ) | `["#0"]` |
| `detector` | Detector name string, used for dataspec strings and other task parameters | `TEST` |
| `dd_enabled` | If true, Data Distribution components will run and process data produced by Readout | `true` |
| `qcdd_enabled` | If true, QualityControl components will run and process data forwarded by `StfBuilder` | `false` |
| `stfb_standalone` | If true, `StfBuilder` runs with `--stand-alone` and `StfSender` is disabled (only if `dd_enabled` is `true`) | `false` |
| `dd_discovery_net_if` | The name of the InfiniBand interface for `StfSender` output (only if `dd_enabled` is `true`) | `lo` |
| `dd_discovery_endpoint` | URI of the Data Distribution Consul instance (only if `dd_enabled` is `true`) | `no-op://` |
| `roc_cleanup_enabled` | Run `roc-cleanup` after environment shutdown | `true` |
| `fmq_cleanup_enabled` | Run `fairmq-shmmonitor -c` after environment shutdown | `true` |
| `fmq_severity` | Severity level for FairMQ (including Data Distribution) `stdout` messages | `info` |
| `fmq_verbosity` | Verbosity level for FairMQ (including Data Distribution) `stdout` messages | `high` |
| `rdh_version` | RDH version for `StfBuilder` (only if `dd_enabled` is `true`) | `no-op://` |
| `odc_enabled` | If true, `o2-aliecs-odc-shim` runs and interfaces with the EPN cluster control | `false` |
| `odc_hostname` | The hostname where ODC (EPN control) is running (only if `odc_enabled` is `true`) | `localhost` |
| `odc_port` | The port where ODC (EPN control) is listening (only if `odc_enabled` is `true`) | `50051` |
| `odc_topology_path` | Path to a DDS topology file, local to `odc_hostname` (only if `odc_enabled` is `true`) | `/etc/o2.d/odc/ex-dds-topology-infinite.xml` |

# Notes on the CI Pipeline

In order to ensure a successful addition or modification of a template (task/workflow), every pull request will run a `walnut check` command against each file individually. 

If there is an error during the execution of `walnut check` command, the pipeline will stop and print out the exit code and the output provided by the command.

These checks are ran automatically against:
*  os: `macOS-latest`, go-version: `1.15.0` 
*  os: `ubuntu-18.04`, go-version: `1.15.0` 
*  `walnut` version: [Control/master](https://github.com/AliceO2Group/Control/tree/master/)

Source code can be found [here.](.github/workflows/template.yml)
