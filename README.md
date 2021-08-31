# RAI Workspace

This workspace is designed as a generic harnass for creating, populating, and querying databases on a local RAI server, using the RAI SDK. It will be extended to cover cloud-based servers and remote data storage.

The goal of this harnass is to test-out the RAI SDK and to facilitate testing Rel behavior. It is currently implemented with the Julia SDK only.

Current capabilities:
- Start a local server, and create or access a local database
- Connect to a remote server, and create or access a remote database
- Populate the database by installing data from local files and defining relations with Rel
- Query the database with custom queries or by querying installed relations
- **Projects** specified by configuration files (a project contains Rel files, data source files, and configuration information for the data and project scenarios)
- Within each project, **scenarios** specified by a configuration file (containing subsets of a project's Rel files and data source files)
- Data loading: csv, json, and rel file support
- Loading individual data or Rel files outside of the project's scope

Upcoming capabilities:
- Python SDK support
- Benchmarking of scenarios
- Data export

## Organization

The two top-level directories are `/julia` for processing configuration files and performing SDK calls and `/projects` containing sub-folders for each project.

```
workspace/
├── julia/
|   ├── activate_rai.jl     Connect to a RAI server or start a local RAI server
|   ├── deploy.jl           User-level functions for installing and querying data
|   ├── helper_functions.jl Helper functions used by insert_data and install_source
|   ├── insert_data.jl      Functions for inserting data from a data file
|   ├── install_source.jl   Functions for installing relations from a Rel file
|   └── local_server.jl       Helper functions for starting a local RAI server
└── projects/
    ├── {{ project name }}           Name of the project
    |   ├── config/
    |   |   ├── data_import.json     Configuration file for all data files in the project
    |   |   └── project.json         Configuration file for all scenarios in the project 
    |   ├── data/
    |   |   ├── {{ data file }}.csv  Data file (csv supported currently)
    |   |   └── ...
    |   └── src/
    |   |   ├── {{ Rel file }}.rel   Rel file (extension ".rel" expected)
    |   |   └── ...
    └── ...
```

## How to run the workspace

The Julia SDK is currently linked to raicode. You must have a local raicode build to use this workspace, even if you plan to use a remote RAI server.

To begin, start a Julia environment in the workspace directory and ensure you have a path to the Julia SDK. (This currently requires a local version of raicode or the binary.)

1. Navigate to the workspace directory and start a Julia session,
```bash
path/to/workspace$ julia
```
2. Provide the path to RAI,
```julia
julia> ENV["RAI_PATH"] = "/path/to/raicode"
```
You may also set this elsewhere, for example in your `~/.bashrc`.

3. Include `activate_rai.jl`,
```julia
julia> include("julia/activate_rai.jl")
```

4. Include `deploy.jl` to access user functions for interacting with the server.

```julia
julia> include("julia/deploy.jl")
```

### Connect to a remote RAI server

Connect to a remote server with,
```julia
julia> set_server("remote-server")
```

This command will set the Management Connection. You can optionally specify the profile you would like to use and the compute as well:

```julia
function set_server(server_type::String;
                    profile::AbstractString="default",
                    compute_name::AbstractString=current_compute_name)
```

If you do not specify the `compute_name` it will default to `rai-workspace-YYYY-MM-DD-xs`, with the current date. Note that this does not _create_ the compute, merely specifies which _already provisioned_ compute to connect with.

The profile you specify should be listed in your `~/.rai/config` file. The config will look something like:

```
[default]
region = us-east
host = azure.relationalai.com
port = 443
access_key = abcdefgh-####-####-####-############
private_key_filename = abcdefgh-privatekey.json
infra = AZURE
```
And the private key, `abcdefgh-privatekey.json` should go in the same folder.

If you do not have credentials for a UI Account, request them via creating an issue in the `relationalai-infra` repo.

### Start a local RAI server

Start the local server with,
```julia
julia> set_server("local-server")
```

If the server starts successfully, the last message you should see will look something like:
```julia
julia> ┌ Info: 2021-08-13T09:29:30.921
└ [SERVER] Starting tcp server on 127.0.0.1:8010.
┌ Info: 2021-08-13T09:29:31.053
└ [SERVER] Enter event loop on 127.0.0.1:8010.
```

### Set the project and scenario

Include `deploy.jl` to access user functions for interacting with the server.

```julia
julia> include("julia/deploy.jl")
```

The project and scenario are set saved as global variables. Once they are set, they will serve as
default values for loading data and relations. Use `set_project` to assign. The only information you must pass is the project name.

```julia
julia> set_project("my_first_project")
```

The scenario value will default to "default". *Every* project should include a default scenario in that project's `project.json` configuration file.

You may optionally set any of the following arguments for `set_project`:
```julia
function set_project(project_name::String; scenario::AbstractString="default",
                     dbname::Symbol=:default, create_db::Bool=true, 
                     overwrite::Bool=true)
```

The optional arguments are:

- **scenario**: String name of a scenario specified in projects.json.
- **dbname**: Name for the database. This will create a new database if it does not yet exist. If set to `:default`, the database will be named `:$(project name)_$(scenario)`. In the example case, `:my_first_project_default`.
- **create_db**: If true, create a new database if dbname does not exist.
- **overwrite**: If true, overwrite database specified by dbname.

### Load data for a scenario

Insert the scenario data by executing `insert_data()`. You must first define the project and scenario with `set_project` before executing.

> **Note:**  Every project should include a default scenario in the project's project.json file.

```julia
julia> insert_data()
```

This function will look at the `project.json` file to determine what files to insert. The example project contains one scenario ("default") with one csv file ("plant_purchases.csv") and one rel file ("tax_data.rel"). It looks like:

```json
{
    "default": {
            "name": "default",
            "deps": [ "purchase_insights" ],
            "data": [ "plant_purchases.csv", "tax_data.rel" ]
        }
}
```

The function `insert_data` will expect `plant_purchases.csv` to be located at `projects/my_first_project/data/plant_purchases.csv`. The configuration information for this data file, and all data files, should be specified in `data_import.json`. For our example, `data_import.json` looks like,

```json
{
    "plant_purchases.csv": {
        "rel": "plant_purchases_csv",
        "optional": false,
        "columns": [
            { "name": "Name", "type": "string" , "required": "true" },
            { "name": "Purchase_Date", "type": "date" , "required": "true" },
            { "name": "Price", "type": "float" , "required": "true" },
            { "name": "Quantity", "type": "int" }
        ]
    }
}
```

> **Note:** The fields "optional" and "required" are not yet used.

The function `insert_data` also expects `tax_data.rel` to be located at `projects/my_first_project/src/tax_data.rel`.

> **Note:** Whether installed as a source (IDB) or inserted as data (EDB), all rel files should be located in the src path of the project.

Relations defined in rel files that are inserted as data are added as EDB relations and can be updated. Installed files (listed in the project under "deps") cannot be updated without overwriting the database and rerunning the scenario.

You may optionally set any of the following arguments for `insert_data`:
```julia
function insert_data(project_name::String=current_project, 
                     scenario::AbstractString=current_scenario,
                     dbname::Symbol=current_dbname, create_db::Bool=false, 
                     overwrite::Bool=true)
```

The optional arguments are:

- **project_name**: String name of the project to add.
- **scenario**: String name of a scenario specified in project.json for the selected project.
- **dbname**: Name for the database.
- **create_db**: If true, create a new database if dbname does not exist.
- **overwrite**: If true, overwrite database specified by dbname.

### Load data from a single file

This is not yet exposed in deploy.jl.

### Install relations for a scenario

As with inserting data, you must first define the project and scenario with `set_project` before executing.

```julia
julia> install_scenario()
```

In the example, `project.json` specifies just one Rel file, "purchase_insights" (see contents of `project.json` above). The function `install_scenario` will expect this file to be located at `projects/my_first_project/src/purchase_insights.rel`.

You may optionally set any of the following arguments for `install_scenario`:
```julia
function install_scenario(project_name::String=current_project, 
                          scenario::AbstractString=current_scenario,
                          dbname::Symbol=current_dbname, sequential::Bool=false)
```

The optional arguments are:

- **project_name**: String name of the project to add.
- **scenario**: String name of a scenario specified in projects.json.
- **dbname**: Name for the database.
- **sequential**: If true, each .rel file will be installed sequentially in the order that it appears in the project config. If false, all .rel files will be joined as a single program and installed in a single transaction.

### Query a scenario

You must provide names for the relations to query (as symbols) and the project name.

```julia
julia> query_scenario([:plant_purchases_csv])
```

To define a relation to query, include the relation code with the argument `rel`.

```julia
julia> query_scenario([:plant_names]; 
                      rel="""
                      def plant_names = plant_purchases_csv[_,:Name]
                      """)
```
You may optionally set any of the following arguments for `query_scenario`:
```julia
function query_scenario(relations::Array{Symbol}; 
                        project_name::String=current_project,
                        scenario::AbstractString=current_scenario,
                        dbname::Symbol=current_dbname,
                        rel::AbstractString="")
```

The optional arguments are:

- **project_name**: String name of the project to add.
- **scenario**: String name of a scenario specified in projects.json.
- **dbname**: Name for the database.
- **rel**: String with rel code that defines the queried relations.

Relations defined with the `rel` argument will not be installed.

### Reinstall a scenario

Delete all non-raicode EDB's and reinstall the current scenario. This is useful if you are developing IDB code and want to iteratively test changes.

```julia
julia> reinstall_scenario()
```

### Replace a relation

Relations created by running `insert_data` (EDB relations) can be changed with one-time updates. The helper function `replace_relation` creates Rel code and runs a query call to delete a relation and replace it with a relation of the same name, with a new definition.

```julia
function replace_relation(relation_name::Symbol,
                          new_definition::String;
                          old_args::Array{Any}=[], new_args::Array{Any}=[],
                          project_name::String=current_project,
                          scenario::AbstractString=current_scenario,
                          dbname::Symbol=current_dbname)
```

- **relation_name**: Relation to replace. Must be defined as an EDB.
- **new_definition**: Rel code string with the new definition of the relation relation_name.
- **old_args**: Arguments for the original relation definition. Depending on what is being deleted and inserted, this may not be necessary to define.
- **new_args**: Arguments for the new relation definition. Depending on what is being deleted and inserted, this may not be necessary to define.
- **project_name**: String name of the project to add.
- **scenario**: String name of a scenario specified in projects.json.
- **dbname**: Name for the database.

Rel is written as:
```c++
def delete[:$(String(relation_name))]$(old_arg_rel) = $(String(relation_name))$(old_arg_rel)
def insert[:$(String(relation_name))]$(new_arg_rel) = $(new_definition)
```

Example 1: Delete the relation `balance` and create a new definition:
```c++
def delete[:balance] = balance
def insert[:balance]("jack",x) = x = 60
```
With `replace_relation`:
```julia
replace_relation(:balance,"x = 60",new_args=['"jack"','x'])
```
