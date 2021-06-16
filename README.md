# FLP Suite Workflow Configuration
The [`ControlWorkflows`](https://github.com/AliceO2Group/ControlWorkflows) repository hosts the configuration tree for AliECS workflow templates (WFT) and task templates (TT).

<!--TOC generated with https://github.com/ekalinin/github-markdown-toc-->
<!--./gh-md-toc --insert /path/to/README.md-->
<!--ts-->
* [FLP Suite Workflow Configuration](#flp-suite-workflow-configuration)
  * [Notes on input data types](#notes-on-input-data-types)
  * [Common workflow variables](#common-workflow-variables)
  * [readout-dataflow workflow variables](#readout-dataflow-workflow-variables)
  * [o2-roc-config workflow variables](#o2-roc-config-workflow-variables)
    * [o2-roc-config common variables](#o2-roc-config-common-variables)
    * [o2-roc-config config-args variables](#o2-roc-config-config-args-variables)
    * [Examples of running the o2-roc-config workflow](#examples-of-running-the-o2-roc-config-workflow)
  * [Integration variables](#integration-variables)
    * [DCS](#dcs)
    * [DD scheduler](#dd-scheduler)
    * [ODC](#odc)
  * [Plugin configuration](#plugin-configuration)
  * [Notes on the CI Pipeline](#notes-on-the-ci-pipeline)
  * [Exporting DPL workflow templates](#exporting-dpl-workflow-templates)
    * [Preparing the DPL command](#preparing-the-dpl-command)
    * [Exporting the templates](#exporting-the-templates)
    * [Exporting templates of workflows which need configuration files](#exporting-templates-of-workflows-which-need-configuration-files)
    * [Generating multinode QC workflows](#generating-multinode-qc-workflows)
    * [Future improvements](#future-improvements)
<!--te-->

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

## Notes on the CI Pipeline

In order to ensure a successful addition or modification of a template (task/workflow), every pull request will run a `walnut check` command against each file individually. 

If there is an error during the execution of `walnut check` command, the pipeline will stop and print out the exit code and the output provided by the command.

These checks are ran automatically against:
*  os: `macOS-latest`, go-version: `1.15.0` 
*  os: `ubuntu-18.04`, go-version: `1.15.0` 
*  `walnut` version: [Control/master](https://github.com/AliceO2Group/Control/tree/master/)

Source code can be found [here.](.github/workflows/template.yml)

## Exporting DPL workflow templates

This piece of documentation explains how to generate a DPL workflow template which should run on an FLP.

All FLPs use the `readout-dataflow` workflow to run the common pieces of software - Readout, STFBuilder, STFSender, ROC and others.
It can also include DPL sub-workflows which may perform some data processing and/or quality control (max. one per FLP).
Additionally, a remote QC workflow can be added (e.g. with Mergers).

All available DPL workflows can be (re)generated with scripts stored in the `scripts` directory.
Use [`generate-all-dpl-workflows.sh`](scripts/generate-all-dpl-workflows.sh) to regenerate all the DPL workflows, or any particular script to regenerate only the selected one.
All scripts should be executed from within the `scripts` directory. 
When adding a new workflow template, please consider providing also a script, so it can be regenerated in case of need. 

### Preparing the DPL command

Before exporting the workflow, one should prepare a DPL command which is able to get data from STFBuilder, process it and send the results to the STFSender.
The first and the last requirements are handled by the input and output DPL proxies.
The simplest possible DPL workflow command for an FLP receives data from STFBuilder and passes it to STFSender without any processing:
```bash
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:TST/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-dpl-output-proxy -b --session default \
  --dataspec 'x:TST/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"'
```
The `--dataspec` arguments define what kind of data is expected both in the input and output proxies.
The `readout-dataflow` workflow requires that the input proxy contains a channel named `readout-proxy`, while the output proxy should provide the channel `downstream`.
This way the AliECS can find the other ends of the channels used by the STFBuilder and STFSender to send and receive data.
There can be only one set of proxies interacting with Data Distribution at the same time.
The pipe `|` character connects the two or more workflows by letting the preceding one transfer its structure to the next one and letting the last execute all the processes (the pipe does not transfer data, just the workflow configuration!).

Let's consider a more realistic example - the PHOS compressor.
In such case, the DPL command looks as follows:
```bash
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:PHS/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-phos-reco-workflow -b --input-type raw --output-type cells --session default --disable-root-output \
  | o2-dpl-output-proxy -b --session default \
  --dataspec 'A:PHS/CELLS/0;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"'
```
Notice that the `dataspecs` of the I/O proxies were changed accordingly to the expected data origin and description.
If you do not know what these should be, you should ask the developer of the workflow in question or investigate yourself the workflow structure by executing it with the `--dump` argument.

While preparing the DPL command, please avoid adding Data Processors which dump data to local files - these might get big during the data-taking and use all available resources.
Also, this particular workflow structure does not depend on any configuration files, so it always stays the same, unlike QC workflows.
We will consider such cases [later in the documentation](#exporting-templates-of-workflows-which-need-configuration-files).

### Exporting the templates

Please make sure that you have built and compiled the same software stack on your setup as the one which will run on the target machines.
If different versions are used, there is a risk that the workflows will not be deployed correctly in case that they were modified.
Exporting workflow templates is possible since O2@v21.14.

To export a workflow template, follow these steps:
1. Load the O2 (and QC if needed) environment:
```bash
alienv enter O2/latest
# or
alienv enter QualityControl/latest # will load also O2
```
2. Go to your local ControlWorkflows repository (clone if needed), preferably create a new branch from master.
3. Run the DPL command with `--o2-control <workflow-name>` argument at the end. For example:
```bash
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:PHS/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-phos-reco-workflow -b --input-type raw --output-type cells --session default --disable-root-output \
  | o2-dpl-output-proxy -b --session default \
  --dataspec 'A:PHS/CELLS/0;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"' \
  --o2-control phos-compressor
```
If there are no problems with the workflow, you will see a similar output:
```bash
[INFO] Dumping the workflow configuration for AliECS.
[INFO] Creating directories 'workflows' and 'tasks'.
[INFO] ... created.
[INFO] Creating a workflow dump 'phos-compressor'.
[INFO] This topology will connect to the channel 'readout-proxy', which is most likely bound outside. Please provide the path to this channel under the name 'path_to_readout_proxy' in the mother workflow.
[INFO] Creating a task dump for 'internal-dpl-clock'.
[INFO] ...created.
[INFO] Creating a task dump for 'readout-proxy'.
[INFO] ...created.
[INFO] Creating a task dump for 'PHOSRawToCellConverterSpec'.
[INFO] ...created.
[INFO] Creating a task dump for 'dpl-output-proxy'.
[INFO] This topology will bind a dangling channel 'downstream'. Please make sure that another device connects to this channel elsewhere.
[INFO] ...created.
[INFO] Creating a task dump for 'internal-dpl-injected-dummy-sink'.
[INFO] ...created.
```
The corresponding workflow template (list of processes to run) will be created in the `workflows` directory and the tasks templates (processes configurations) will be put under the `tasks` directory.

4. Commit the new files and push to a remote branch.
One can run it by pointing the AliECS to respective branch, choosing the `readout-dataflow` workflow in the AliECS GUI and adding the parameter `dpl_workflow : <workflow_name>` in the advanced configuration.
If running a setup with multiple detectors, add the 3-letter detector prefix to the key (e.g. `tof_dpl_workflow`).
After confirming that it works, make a PR to the main ControlWorkflows' master branch.

### Exporting templates of workflows which need configuration files

Some DPL workflows require configuration files to run correctly.
Also the process names, channel names and their arrangement might depend on such configuration files.
Quality Control workflows fall into this category.
In such case, exporting templates require a bit more babysitting.

Let's consider a workflow consisting of I/O proxies, MFT decoder and MFT Digit QC Task:
```bash
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-itsmft-stf-decoder-workflow -b --runmft --digits --no-clusters --no-cluster-patterns \
  | o2-dpl-output-proxy -b --session default \
  --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  | o2-qc -b --config json://'${QUALITYCONTROL_ROOT}'/etc/mft-digit-qc-task-FLP-0-TaskLevel-0.json
```
If we were to generate and use such workflow template, the QC would look for the QC configuration file under the same path as during the export, which might not be accesible on the target machine.
Thus, we will substitute it with the expected path of such file in Consul (the configuration store).
To do so, one may follow the script below (see the associated comments):
```bash
#!/usr/bin/env bash
set -x; # debug mode
set -e; # exit on error
set -u; # exit on undefined variable

# Variables
WF_NAME=mft-digits-qc
QC_GEN_CONFIG_PATH='json://'${QUALITYCONTROL_ROOT}'/etc/mft-digit-qc-task-FLP-0-TaskLevel-0.json'
QC_FINAL_CONFIG_PATH='consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/'${WF_NAME}'-{{ it }}'
QC_CONFIG_PARAM='qc_config_uri'

# Generate the AliECS workflow and task templates
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-itsmft-stf-decoder-workflow -b --runmft --digits --no-clusters --no-cluster-patterns \
  | o2-dpl-output-proxy -b --session default \
  --dataspec 'x:MFT/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  | o2-qc --config ${QC_GEN_CONFIG_PATH} -b \
  --o2-control $WF_NAME

# Add the final QC config file path as a variable in the workflow template
ESCAPED_QC_FINAL_CONFIG_PATH=$(printf '%s\n' "$QC_FINAL_CONFIG_PATH" | sed -e 's/[\/&]/\\&/g')
# Will work only with GNU sed (Mac uses BSD sed)
sed -i /defaults:/\ a\\\ \\\ "${QC_CONFIG_PARAM}":\ \""${ESCAPED_QC_FINAL_CONFIG_PATH}"\" workflows/${WF_NAME}.yaml

# Find all usages of the QC config path which was used to generate the workflow and replace them with the template variable
ESCAPED_QC_GEN_CONFIG_PATH=$(printf '%s\n' "$QC_GEN_CONFIG_PATH" | sed -e 's/[]\/$*.^[]/\\&/g');
# Will work only with GNU sed (Mac uses BSD sed)
sed -i "s/""${ESCAPED_QC_GEN_CONFIG_PATH}""/{{ ""${QC_CONFIG_PARAM}"" }}/g" workflows/${WF_NAME}.yaml tasks/${WF_NAME}-*
```

After these steps, the workflow should be ready to be committed and tested.
However, one should also make sure that the required config file is available in Consul under the correct path.
To do so, one can add it using the Consul GUI (Key/Value panel).
Otherwise, to install it with each FLP suite, one should add a file template in the [System configuration](https://gitlab.cern.ch/AliceO2Group/system-configuration/) repository under the path `ansible/roles/quality-control/templates` similarly to the other QC files (if it is actually QC).
Then one should add the file to the corresponding sub-task in `ansible/roles/quality-control/tasks/main.yml`.

### Generating multinode QC workflows

If the expected production setup includes QC running in parallel on many nodes, one should generate two workflow templates - one for the FLP part, another one which should run on a QC server.
First, one should prepare DPL commands and QC config file according to the [multinode QC setup documentation](https://github.com/AliceO2Group/QualityControl/blob/master/doc/Advanced.md#multi-node-setups).
Then, the two workflows should be generated with `-local` and `-remote` name suffixes respectively, as it is done e.g. in [`scripts/qcmn-daq.sh`](scripts/qcmn-daq.sh).
Following this example, the full setup can be run by adding the following parameters in the advanced configuration panel:
```
"dpl_workflow" : "qcmn-daq-local"
"qc_remote_workflow" : "qcmn-daq-remote"
```

### Future improvements

With the future releases we plan to allow for Just-In-Time workflow translation.
It means that one will not have to export the templates manually anymore and they will only need to provide a file with the standalone DPL command.

### Exporting worfklows for Dummies

If you have read everything above, you can now follow these simplified instructions. 

3. Access a FLP with the proper FLP Suite
1. Prepare the workflow
    2. Clone ControlWorkflows from your fork: `git clone https://github.com/<yourGHusername>/ControlWorkflows.git`
    3. Make sure that you are in line with the correct branch:
       ```
       git remote add upstream https://github.com/AliceO2Group/ControlWorkflows.git
       git fetch upstream 
       git checkout flp-suite-v0.xx.0
       git checkout -b my-branch
       ```
    3. Update a script in `ControlWorkflows/scripts` or add a new one
    4. Run the script to re-generate the workflow(s): `cd ControlWorkflows/scripts ; ./my-script.sh`
    1. If you need to use config files, refer to [this section](#exporting-templates-of-workflows-which-need-configuration-files)
    5. Commit and push the changes
1. Test it
    1. Add the fork to the control: `coconut repo add github.com/<yourGHusername>/ControlWorkflows.git`
    2. In the ECS, create a new environment.
    3. Set the fork and the branch to match yours.
    4. Add the variable `dpl_workflow` and set it to the name of the workflow
    1. Add the variable `log_task_output` and set it to `all` to make sure you can see the output of the tasks in the Infologger.
    4. Do not enable QC but enable DD.
    5. Run and check that everything is fine
