# The FLP Suite Workflow Configuration repository
This repository hosts the configuration tree for AliECS workflows and tasks.

## Common workflow variables

All AliECS variables are strings. Some workflow templates can choose to treat a string variable as a JSON payload, with built in functions such as `ToJson`/`FromJson`, but they are always provided as strings by the user, and stored as strings in the key-value map.

| Variable | Description | Example |
| :--- | :--- | :--- |
| `hosts` | JSON-formatted list of hosts to control the scale of certain workflows | `["myhost1","myhost2"]` |
| `readout_cfg_uri` | URI of a Readout configuration payload | `"file:/home/flp/readout.cfg"` |
