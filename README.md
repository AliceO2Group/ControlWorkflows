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
| `log_task_output` | Forward task output to InfoLogger and stdout, stdout only, or nowhere | `all`, `stdout` or `none` | depends on WFT, usually `none` |
| `readout_cfg_uri` | URI of a Readout configuration payload | `consul-ini://{{ consul_endpoint }}/o2/components/readout/ANY/any/readout-standalone-{{ task_hostname }}` | depends on WFT |
| `user` | Name of the Linux user that should run all tasks | `root` | `flp` |


## `readout-dataflow` workflow variables

All variables are optional.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `roc_ctp_emulator_enabled` | If true, `o2-roc-ctp-emulator` will run during `START` to get data from CRU without LTU | `false` |
| `roc_trigger_mode` | Trigger mode for `o2-roc-ctp-emulator` (only if `roc_ctp_emulator_enabled` is `true` ) | `continuous` |
| `roc_ctp_emulator_endpoints` | List of CRU endpoints to emulate trigger (only if `roc_ctp_emulator_enabled` is `true` ) | `["#0"]` |
| `detector` | Detector name string, used for dataspec strings and other task parameters | `TEST` |
| `dd_enabled` | If true, Data Distribution components will run and process data produced by Readout | `true` |
| `qcdd_enabled` | If true, QualityControl components will run and process data forwarded by `StfBuilder` | `false` |
| `stfb_standalone` | If true, `StfBuilder` runs with `--stand-alone` and `StfSender` is disabled (only if `dd_enabled` is `true`) | `false` |
| `dd_discovery_net_if` | The name of the InfiniBand interface for `StfSender` output (only if `dd_enabled` is `true`) | `lo` |
| `dd_discovery_endpoint` | URI of the Data Distribution Consul instance (only if `dd_enabled` is `true`) | `no-op://` |
| `roc_cleanup_enabled` | Run `o2-roc-cleanup` after environment shutdown | `true` |
| `fmq_cleanup_enabled` | Run `fairmq-shmmonitor -c` after environment shutdown | `true` |
| `fmq_severity` | Severity level for FairMQ (including Data Distribution) `stdout` messages | `info` |
| `fmq_verbosity` | Verbosity level for FairMQ (including Data Distribution) `stdout` messages | `high` |
| `rdh_version` | RDH version for `StfBuilder` (only if `dd_enabled` is `true`) | `no-op://` |


## `o2-roc-config` workflow variables

The workflow requires a string json array of the hosts (e.g `["flp1","flp1"]`) when it is executed. It will retrieve all the cru cards and their endpoints. 

The default behaviour, if no variables are passed, is to apply the configuration from the `o2/components/readoutcard/<host>/cru/<card>/<endpoint>` to all cards and endpoints. All the parameters along with the default values are provided on the following tables. Examples on how to execute the workflow with coconut can be found [here](#examples-of-running-the-`o2-roc-config`-workflow).

### `o2-roc-config` common variables
All variables are optional.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `roc_config_uri_enabled` | If true, o2-roc-config will run using the `--config-uri` flag and the config found at the consul service under the `{{ consul_prefix }}/{{ host }}/cru/{{ card }}/` | `"true"` |
| `consul_port` | The port that consul service is running | `8500` |
| `consul_prefix` | The consul prefix where the cru configuration is stored | `o2/components/readoutcard` |
| `cards` | A string json array with all the cards in the host, provided by `CRUCardsForHost(hostname)`(e.g `["1251","1276"]`)  | `{{CRUCardsForHost( hostname )}}` |
| `card_endpoints` | A string with card endpoints separated by spaces, provided by `{{EndpointsForCRUCard( host, card )}}` (e.g `0 1`) | `{{EndpointsForCRUCard( host, card )}}` |

### `o2-roc-config` config-args variables

This will be executed when `roc_config_uri_enabled` is disabled (`"roc_config_uri_enabled":"false"`).

All variables are optional.

| Variable | Description | Default |
| :--- | :--- | :--- |
| `rocConfigLinks` | Value to be passed to the `--links` flag (e.g `1,2,3` or `0-11`) | `0` |
| `rocConfigAllowRejection` | If true, the flag `--allow-rejection` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigClock` | Value to be passed to the `--clock` flag | `LOCAL` |
| `rocConfigCruId` | Value to be passed to the `--cru-id` flag | `0x0` |
| `rocConfigCrocId` | Value to be passed to the `--crorc-id` flag | `0x0` |
| `rocConfigDatapathMode` | Value to be passed to the `--datapathmode` flag | `PACKET` |
| `rocConfigDownstreamData` | Value to be passed to the `--downstreamdata` flag | `CTP` |
| `rocConfigGbtMode` | Value to be passed to the `--gbtmode` flag | `GBT` |
| `rocConfigLoopback` | If true, the flag `--loopback` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigPonUpstream` | If true, the flag `--pon-upstream` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigDynOffset` | If true, the flag `--dyn-offset` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigOnuAddress` | Value to be passed to the `--onu-address` flag | `0` |
| `rocConfigForceConfig` | If true, the flag `--force-config` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigBypassFwCheck` | If true, the flag `--bypass-fw-check` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigTriggerWindowSize` | Value to be passed to the `--trigger-window-size` flag | `1000` |
| `rocConfigNoGBT` | If true, the flag `--no-gbt` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigUserLogic` | If true, the flag `--user-logic` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigRunStats` | If true, the flag `--run-stats` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigUserAndCommonLogic` | If true, the flag `--user-and-common-logic` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigNoTfDetection` | If true, the flag `--no-tf-detection` will be set to the `o2-roc-config` command | `"false"` |
| `rocConfigTfLength` | Value to be passed to the `--tf-length` flag | `256` |
| `rocConfigSystemId` | Value to be passed to the `--system-id` flag | `0x0` |
| `rocConfigFEEId` | Value to be passed to the `--fee-id` flag | `0x0` |

### Examples of running the `o2-roc-config` workflow

Below there are some examples on how to execute the `o2-roc-config` workflow:
```
# Run o2-roc-config for all the cards and all endpoints using the configuration stored in consul under o2/components/readoutcard/<host>/cru/
coconut e c -a -w o2-roc-config -e '{"hosts":["<host>"]}'

# Run o2-roc-config for all the cards and specific endpoint (0) using the configuration stored in consul under o2/components/readoutcard/<host>/cru/
coconut e c -a -w o2-roc-config -e '{"hosts":["<host>"],"card_endpoints":"0"}'

# Run o2-roc-config for a specific card (1275) and all endpoints using the configuration stored in consul under o2/components/readoutcard/<host>/cru/1275/
coconut e c -a -w o2-roc-config -e '{"hosts":["<host>"],"cards":["1275"]}'

# Run o2-roc-config using the flag arguements with default values
coconut e c -a -w o2-roc-config -e '{"hosts":["<host>"],"roc_config_uri_enabled":"false"}'

# Run o2-roc-config using the flag arguements and `--force-config
coconut e c -a -w o2-roc-config -e '{"hosts":["<host>"],"roc_config_uri_enabled":"false", "rocConfigForceConfig":"true"}'
```

## Integration variables

### DCS

| Variable | Description | Default |
| :--- | :--- | :--- |
| `dcs_enabled` | If true and if the DCS plugin is enabled and configured, AliECS interfaces with the DCS service | `false` |
| `dcs_detectors` | The list of detectors for DCS SOR/EOR, passed as JSON list (see [protofile](https://github.com/AliceO2Group/Control/blob/master/core/integration/dcs/protos/dcs.proto#L135) for allowed values) | `["NULL_DETECTOR"]` |
| `dcs_sor_parameters` | A key-value map of string parameters for DCS SOR, passed as JSON object | `{}` (empty JSON document) |
| `dcs_eor_parameters` | A key-value map of string parameters for DCS EOR, passed as JSON object | `{}` (empty JSON document) |

Example: `coconut env create -w readout-dataflow -e '{"hosts":"[\"alio2-cr1-flp999\"]","dcs_enabled":"true","dcs_detectors":"[\"TPC\",\"ITS\"]"}'`

### DD scheduler

| Variable | Description | Default |
| :--- | :--- | :--- |
| `ddsched_enabled` | If true and if the DD scheduler plugin is enabled and configured, AliECS interfaces with the DD scheduler | `false` |

Please note that `dd_enabled`, which enables the FLP side of the Data Distribution chain, must also be `true` for the DD scheduler to work, and incoming connections to `StfSender` instances must be possible. The runtime variables `dd_discovery_ib_hostname`, `dd_discovery_stfb_id` and `dd_discovery_stfs_id` are automatically generated by the `readout-dataflow` workflow template and used by the DD scheduler plugin. In most cases no attempt should be made to override them.

### ODC

| Variable | Description | Default |
| :--- | :--- | :--- |
| `odc_enabled` | If true and if the ODC plugin is enabled and configured, AliECS interfaces with the EPN cluster control | `false` |
| `odc_plugin` | The resource management system plugin to be used by ODC for deployment | empty string |
| `odc_resources` | A resource declaration used by ODC for deployment | empty string |
| `odc_topology_path` | Path to a DDS topology file, local to the ODC target machine | `/etc/o2.d/odc/ex-dds-topology-infinite.xml` |

Any variable prefixed with `odc_` will be pushed to all ODC-controlled hosts as a task configuration parameter (ultimately a FairMQ options key-value). For example, setting `odc_my_value: someValue` on AliECS pushes the key-value pair `my_value: someValue` to ODC, which in turn propagates it to all controlled tasks.

## Plugin configuration

In order for any of the integration variables to work, the AliECS core must have the relevant plugins enabled. The following plugin configuration parameters can be passed to the AliECS core at startup time as command line flags, or as YAML/JSON key-values in Consul `/o2/components/aliecs/ANY/any/settings`. Prefix with `//` if providing an IP address instead of a hostname.

      --integrationPlugins strings                              List of integration plugins to load (default: empty)
      --dcsServiceEndpoint host:port                            Endpoint of the DCS gRPC service (host:port) (default "//127.0.0.1:50051")
      --dcsServiceUseSystemProxy                                When true the https_proxy, http_proxy and no_proxy environment variables are obeyed
      --ddSchedulerEndpoint host:port                           Endpoint of the DD scheduler gRPC service (host:port) (default "//127.0.0.1:50052")
      --ddSchedulerUseSystemProxy                               When true the https_proxy, http_proxy and no_proxy environment variables are obeyed
      --odcEndpoint host:port                                   Endpoint of the ODC gRPC service (host:port) (default "//127.0.0.1:50053")
      --odcUseSystemProxy                                       When true the https_proxy, http_proxy and no_proxy environment variables are obeyed

Example:
```
integrationPlugins:
  - dcs
  - ddsched
  - odc
dcsServiceEndpoint: some-host:50051
ddSchedulerEndpoint: some-other-host-ib:50000
odcEndpoint: yet-another-host-ib:22334
```

# Notes on the CI Pipeline

In order to ensure a successful addition or modification of a template (task/workflow), every pull request will run a `walnut check` command against each file individually. 

If there is an error during the execution of `walnut check` command, the pipeline will stop and print out the exit code and the output provided by the command.

These checks are ran automatically against:
*  os: `macOS-latest`, go-version: `1.15.0` 
*  os: `ubuntu-18.04`, go-version: `1.15.0` 
*  `walnut` version: [Control/master](https://github.com/AliceO2Group/Control/tree/master/)

Source code can be found [here.](.github/workflows/template.yml)
