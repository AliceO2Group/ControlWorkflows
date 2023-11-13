# FLP Suite Workflow Configuration
The [`ControlWorkflows`](https://github.com/AliceO2Group/ControlWorkflows) repository hosts the configuration tree for AliECS workflow templates (WFT) and task templates (TT).

<!--TOC generated with https://github.com/ekalinin/github-markdown-toc-->
<!--./gh-md-toc --insert /path/to/README.md-->
<!--ts-->
* [FLP Suite Workflow Configuration](#flp-suite-workflow-configuration)
   * [Notes on input data types](#notes-on-input-data-types)
   * [Common workflow variables](#common-workflow-variables)
      * [Examples of running the o2-roc-config workflow](#examples-of-running-the-o2-roc-config-workflow)
   * [Integration variables](#integration-variables)
      * [DCS](#dcs)
      * [DD scheduler](#dd-scheduler)
      * [ODC](#odc)
   * [Plugin configuration](#plugin-configuration)
   * [Adding DPL workflows](#adding-dpl-workflows)
      * [Quick reference](#quick-reference)
      * [Introduction](#introduction)
      * [FLP workflows](#flp-workflows)
      * [Adding QC to FLP workflows](#adding-qc-to-flp-workflows)
      * [Adding multinode QC to FLPs](#adding-multinode-qc-to-flps)
         * [Parallel QC running on EPNs](#parallel-qc-running-on-epns)
         * [Different parallel QC running on FLPs and EPNs](#different-parallel-qc-running-on-flps-and-epns)
      * [JIT DPL workflow generation](#jit-dpl-workflow-generation)
         * [Useful details](#useful-details)
      * [Exporting the templates to files](#exporting-the-templates-to-files)
         * [Debugging with custom-set DPL commands](#debugging-with-custom-set-dpl-commands)
   * [Notes on the CI Pipeline](#notes-on-the-ci-pipeline)
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
| `log_task_stdout` | Forward task stdout to InfoLogger and executor stdout, executor stdout only, or nowhere | `all`, `stdout` or `none` | depends on WFT, usually `none` |
| `log_task_stderr` | Forward task stderr to InfoLogger and executor stdout, executor stdout only, or nowhere | `all`, `stdout` or `none` | depends on WFT, usually `none` |
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
## Adding DPL workflows

### Quick reference

If you just need a procedure to come back to, you can now follow these simplified instructions. 

1. Prepare the workflow
    1. Clone ControlWorkflows from your fork: `git clone https://github.com/<yourGHusername>/ControlWorkflows.git`
    2. Make sure that you are in line with the correct branch:
       ```
       git remote add upstream https://github.com/AliceO2Group/ControlWorkflows.git
       git fetch upstream 
       git checkout flp-suite-v0.xx.0
       git checkout -b my-branch
       ```
    3. Update a DPL command in `ControlWorkflows/jitscripts` or add a new one
    4. If you need to use config files, add or update them in Consul
    5. Add the new workflow names to the lists in `workflows/readout-dataflow.yaml`
    6. Commit and push the changes
3. Test it
    1. Add the fork to the AliECS or ask the FLP team to do so: `coconut repo add github.com/<yourGHusername>/ControlWorkflows.git`
    2. Refresh the repository (refresh button in the AliECS GUI)
    3. In the ECS, create a new environment.
    4. Set the fork and the branch to match yours.
    5. Select the added or updated FLP workflow in the FLP workflows panel.
    6. If using a QC node workflow, enable the "QC node workflows" button and select the workflow.
    7. Optionally add the variable `log_task_output` and set it to `all` to make sure you can see the output of the tasks in the Infologger.
    8. Run and check that it starts and stops without failures.
4. Make a PR to the master ControlWorkflows

### Introduction

This repository contains configuration of DPL workflows which should run on FLPs and QC nodes.
EPN workflows are defined in the [O2DPG](https://github.com/AliceO2Group/O2DPG/tree/master/DATA/production) repository.

For data-taking environments, we use the master workflow template [`readout-dataflow`](workflows/readout-dataflow.yaml). 
Within, one can declare which DPL workflows it may be include, for example:
```yaml
  mid_dpl_workflow: !public
    value: "none"
    type: string
    label: "MID FLP workflow"
    description: "Workflow to execute on the FLPs of this detector"
    widget: dropDownBox
    panel: FLP_Workflows
    values:
      - none
      - mid-raw-decoder
      - mid-digits-qcmn-local
      - minimal-dpl
      - qc-daq
      - qcmn-daq-local
  mid_qc_remote_workflow: !public
    value: "none"
    type: string
    label: "MID QC node workflow"
    description: "Workflow to execute on QC servers for this detector"
    widget: dropDownBox
    panel: FLP_Workflows
    values:
      - none
      - mid-qcmn-epn-digits
      - mid-digits-qcmn-remote
      - mid-full-qcmn-remote
      - qcmn-daq-remote
      - mid-calib-qcmn-remote
```
The names listed in the `values` arrays correspond to files with DPL commands located in the [`jit`](jit) directory. 
These workflows can be then selected in the AliECS GUI for the concrete detectors.
During creation of an environment, AliECS generates workflow & task templates Just-In-Time (JIT) or reuses the most recent ones if the workflow, software version and config files have not changed.

Thus, to add a new workflow, one should add a file with the DPL command to [`jit`](jit) and its name to the corresponding `values` array in [`readout-dataflow`](workflows/readout-dataflow.yaml).
To understand some details of how the DPL commands should look like and JIT workflow generation, please read the sections below.

### FLP workflows

DPL workflows on FLPs should always receive data from STFBuilder, optionally process them and send to STFSender.
The first and the last requirements are handled by the input and output DPL proxies.
Note that any o2-dpl-raw-proxy that receives data from DataDistribution must add the command line argument "--inject-missing-data".
(This option must not be set if the data does not come from DataDistribution!)
The simplest possible DPL workflow command for an FLP receives data from STFBuilder and passes it to STFSender without any processing:
```bash
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:TST/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --inject-missing-data \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-dpl-output-proxy --environment "DPL_OUTPUT_PROXY_ORDERED=1" -b --session default \
  --dataspec 'x:TST/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"'
```
The `--dataspec` arguments define what kind of data is expected both in the input and output proxies.
The presence of the `DPL_OUTPUT_PROXY_ORDERDED` env var is required by the DPL to correctly order output proxies.
The `readout-dataflow` workflow requires that the input proxy contains a channel named `readout-proxy`, while the output proxy should provide the channel `downstream`.
This way the AliECS can find the other ends of the channels used by the STFBuilder and STFSender to send and receive data.
There can be only one set of proxies interacting with Data Distribution at the same time.
The pipe `|` character connects the two or more workflows by letting the preceding one transfer its structure to the next one and letting the last execute all the processes (the pipe does not transfer data, just the workflow configuration!).

Let's consider a more realistic example - the PHOS compressor.
In such case, the DPL command looks as follows:
```bash
o2-dpl-raw-proxy -b --session default \
  --dataspec 'x:PHS/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --inject-missing-data \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-phos-reco-workflow -b --input-type raw --output-type cells --session default --disable-root-output \
  | o2-dpl-output-proxy --environment "DPL_OUTPUT_PROXY_ORDERED=1" -b --session default \
  --dataspec 'A:PHS/CELLS/0;dd:FLP/DISTSUBTIMEFRAME/0' \
  --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=1,transport=shmem"'
```
Notice that the `dataspecs` of the I/O proxies were changed accordingly to the expected data origin and description.
If you do not know what these should be, you should ask the developer of the workflow in question or investigate yourself the workflow structure by executing it with the `--dump` argument.

While preparing the DPL command, please avoid adding Data Processors which dump data to local files - these might get big during the data-taking and use all available resources.

### Adding QC to FLP workflows

In case you would like to run the full QC chain (Tasks, Checks, QCDB upload, PostProcessing) on an FLP, just add the QC executable to the DPL command, as in the example below.
Use `consul-json://` as the backend and the template variable `{{ consul_endpoint}}` for the Consul hostname.
```
o2-dpl-raw-proxy -b --session default --dataspec 'A1:FDD/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --inject-missing-data --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' \
  | o2-fdd-flp-dpl-workflow -b --session default --output-dir=/tmp --nevents 10000 --configKeyValues 'NameConf.mCCDBServer=http://127.0.0.1:8084;' \
  | o2-dpl-output-proxy --environment DPL_OUTPUT_PROXY_ORDERED=1 -b --session default --dataspec 'digits:FDD/DIGITSBC/0;channels:FDD/DIGITSCH/0;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"' \
  | o2-qc --config consul-json://{{ consul_endpoint }}/o2/components/qc/ANY/any/fdd-digits-qc -b --configKeyValues 'NameConf.mCCDBServer=http://127.0.0.1:8084;'
```

### Adding multinode QC to FLPs

If the expected production setup includes QC running in parallel on many FLPs, one should generate two workflow templates - one for the FLP part, another one which should run on a QC server.
First, one should prepare DPL commands and QC config file according to the [multinode QC setup documentation](https://github.com/AliceO2Group/QualityControl/blob/master/doc/Advanced.md#multi-node-setups).
Then, at least two DPL workflows should be added, one (or more) for FLPs and one for QC node, which will merge and check the results. The first usually use the `-local` suffix in the name, the latter use `-remote`.

#### Parallel QC running on EPNs

In this case, the local part of the QC workflow is run on EPNs (controlled by ODC), while the remote part is still executed on QC servers (controlled directly by AliECS).
Both parts should use the same version of QC and the underlying software stack.

First, please make sure that the QC config file contains valid `"remoteMachine"` and `"remotePort"` parameters, as they are not dynamically assigned for connections between the two control systems.
The remote machine name might need the `.cern.ch` suffix.
Please use the port number within the range allocated to your subsystem, as in the table below.
It is highly advised to check the connection with a simple TCP client/server application beforehand (e.g. `nc`).
Also, do not forget to add `"localControl" : "odc"` in the QC task configuration, which will make AliECS templates avoid dynamic resource assignement.

**Subsystem port ranges for remote connections from EPNs**

Subsystem | Port range start | Port range end
--------- | ---------------- | ---------------
CPV       | 29000            | 29049
CTP       | 29050            | 29099
DAQ       | 29100            | 29149
EMC       | 29150            | 29199
FDD       | 29200            | 29249
FT0       | 29250            | 29299
FV0       | 29300            | 29349
GLO       | 29350            | 29399
HMP       | 29400            | 29449
ITS       | 29450            | 29499
MCH       | 29500            | 29549
MFT       | 29550            | 29599
MID       | 29600            | 29649
PHS       | 29650            | 29699
PID       | 29700            | 29749
TOF       | 29750            | 29799
TPC       | 29800            | 29849
TRD       | 29850            | 29899
ZDC       | 29900            | 29949

Please contact the PDP team for details on running the local QC workflows (the part running on EPN).

The QC server part requires a DPL command file in the `jit` directory, similarly to the case of running parallel QC on FLPs.

#### Different parallel QC running on FLPs and EPNs

Currently recommended way to approach this is to combine the FLP and EPN QC config files and use different `"localMachines"` for them.
Then, one can use different `--host` parameter to the local QC workflows to indicate which tasks should be running in the given environment.

The remote QC workflow should be just one.

### JIT DPL workflow generation

#### Useful details

The JIT generation system relies on the existence & health of the following parts:

1. DPL command provided
   - The full DPL command can be found in `ControlWorfklows/jit/[workflow name]`
   - Alternatively, a custom DPL command can be provided through the "Advanced
      Configuration" panel, which will **take precedence** over the workflow
      normally selected through the interface. See the next subsection for details.
2. Consul payloads (e.g. QC config files) contained in the DPL command
   - These are parsed from the provided DPL command string and Consul is queried
      regarding their version to ensure freshness.
3. JIT-specific env vars, which are common to all JIT-generated workflows
   - These are expected on the deployment's Consul instance under
      `o2/components/aliecs/[defaults|vars]/jit_env_vars`
4. The O2 & QualityControl versions
   - The O2 & QualityControl RPM versions are queried by AliECS to ensure workflow freshness.
5. The command provided either in the file or via a parameter in the GUI should be a one-liner.

### Exporting the templates to files

It is very unlikely that you will need this.

In case that you would like to generate workflow and task templates, which are normally generated automatically by AliECS with the JIT translation, use the following instructions.

Please make sure that you are using the same software stack as the one which will run on the target machines.
If different versions are used, there is a risk that the workflows will not be deployed correctly in case that they were modified.

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
  --dataspec 'x:PHS/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --inject-missing-data \
  --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=1"' \
  | o2-phos-reco-workflow -b --input-type raw --output-type cells --session default --disable-root-output \
  | o2-dpl-output-proxy --environment "DPL_OUTPUT_PROXY_ORDERED=1" -b --session default \
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

In case that a DPL workflow uses configuration files, you might need to replace their paths with the ones that should be used in the target setup.

#### Debugging with custom-set DPL commands

A templated DPL command may be passed through the `dpl_command` variable, prefixed with the detector code (
e.g. `its_dpl_command` for the ITS). The variable may be set through the AliECS GUI environment creation page under
the "Advanced Configuration" panel.

For example, the equivalent of the [minimal DPL workflow](./workflows/minimal-dpl.yaml) can be achieved by setting the
following KV pair (assuming ITS as a target):

- through the "Add single pair:" key and value fields.

*key*: `its_dpl_command`

*value*:

```bash
o2-dpl-raw-proxy -b --session default --dataspec 'x:{{ detector }}/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --inject-missing-data --readout-proxy '--channel-config "name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10"' | o2-dpl-output-proxy -b --session default --dataspec 'x:{{ detector }}/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config "name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem"'
```

- through the "Add a JSON with multiple pairs:" field (make sure to escape the inner `"`):

```json
{
  "its_dpl_command": "o2-dpl-raw-proxy -b --session default --dataspec 'x:{{ detector }}/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --inject-missing-data --readout-proxy '--channel-config \"name=readout-proxy,type=pull,method=connect,address=ipc:///tmp/stf-builder-dpl-pipe-0,transport=shmem,rateLogging=10\"' | o2-dpl-output-proxy -b --session default --dataspec 'x:{{ detector }}/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0' --dpl-output-proxy '--channel-config \"name=downstream,type=push,method=bind,address=ipc:///tmp/stf-pipe-0,rateLogging=10,transport=shmem\"'"
}
```

_Everything described in this subsection for the `dpl_command` for FLP workflows is also applicable
to the `qc_dpl_command` for QC node workflows._

## Notes on the CI Pipeline

In order to ensure a successful collaboration with [AliECS GUI](https://github.com/AliceO2Group/WebUi/tree/dev/Control#control-gui), every pull request will run a `git diff` command to ensure no changes are done to the naming of certain variables (full list [here](https://github.com/AliceO2Group/WebUi/tree/dev/Control#list-of-fixed-variables-used-by-aliecs-gui-for-user-logic)) that are used on the AliECS GUI side. 

If the checks identify any such breaking changes, the pipeline will fail with information on what labels were identified. In such case the developer of AliECS GUI should be notified before the pull request is merged. 

These checks are ran automatically against `macOS-latest`.

Source code can be found [here.](.github/workflows/gui-checks.yml)

### Future improvements

With the future releases we plan to allow for Just-In-Time workflow translation.
It means that one will not have to export the templates manually anymore and they will only need to provide a file with the standalone DPL command.


