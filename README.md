# RAI Workspace

This workspace is designed as a generic harnass for creating, populating, and querying databases on a local RAI server, using the Julia SDK. It will be extended to cover cloud-based servers and remote data storage.

The goal of this harnass is to test-out the Julia SDK and to facilitate testing Rel behavior.

Current capabilities:
- Start a local server, create a local database
- Populate the database by installing data from files and defining relations with Rel
- Query the database with custom queries or by querying installed relations
- **Projects** specified by configuration files (a project contains Rel files, data source files, and configuration information for the data and project scenarios)
- Within each project, **scenarios** specified by a configuration file (containing subsets of a project's Rel files and data source files)
- Data loading: csv file support
- Loading individual data or Rel files outside of the project's scope

Upcoming capabilities:
- Benchmarking of scenarios
- Data loading: json file support
- Data export

## Organization

The two top-level directories are `/julia` for processing configuration files and performing SDK calls and `/projects` containing sub-folders for each project.

```
workspace/
|
├── julia/
|   ├── activate_rai.jl     Start a RAI server
|   ├── deploy.jl           User-level functions for installing and querying data
|   ├── install_data.jl     Helper functions for installing data from a data file
|   ├── install_source.jl   Helper functions for installing relations from a Rel file
|   └── rai_server.jl       Helper functions for starting a RAI server
├── projects/
|   ├── {{ project name }}           Name of the project
|   |   ├── config/
|   |   |   ├── data_import.json     Configuration file for all data files in the project
|   |   |   └── project.json         Configuration file for all scenarios in the project 
|   |   ├── data/
|   |   |   ├── {{ data file }}.csv  Data file (csv supported currently)
|   |   |   └── ...
|   |   └── src/
|   |   |   ├── {{ Rel file }}.rel   Rel file (extension ".rel" expected)
|   |   |   └── ...
|   └── ...
```

## How to run the workspace

### Start a RAI server

The Julia SDK is currently linked to raicode. You must have a local raicode build to use this workspace, even if you plan to use a remote RAI server.

1. Navigate to the workspace directory and start a Julia session
```bash
path/to/workspace$ julia
```
2. Provide the path to RAI
```julia
julia> ENV["RAI_PATH"] = "/path/to/raicode"
```

3. Start the RAI server locally
```julia
julia> include("julia/activate_rai.jl")
```

If the server starts successfully, the last message you should see will look something like:
```julia
julia> ┌ Info: 2021-08-13T09:29:30.921
└ [SERVER] Starting tcp server on 127.0.0.1:8010.
┌ Info: 2021-08-13T09:29:31.053
└ [SERVER] Enter event loop on 127.0.0.1:8010.
```

4. Include `deploy.jl` to access user functions for interacting with the server.
```julia
julia> include("julia/deploy.jl")
```

### Load data for a scenario

The only information you must provide is the project name. The scenario will default to "default". Every project should include a default scenario in `project.json`.

```julia
julia> install_data("my_first_project")
```

In this example, data stored in `projects/my_first_project/data` will be loaded if it specified in the scenario `default` under `data` in the project.json file. The project.json file for the example project contains one csv file ("plant_purchases.csv") and it looks like:

```json
{
    "default": {
            "name": "default",
            "deps": [ "purchase_insights" ],
            "data": [ "plant_purchases.csv" ]
        }
}
```

In the example, project.json specifies just one data file, "plant_purchases.csv" The function `install_data` will expect this file to be located at "projects/my_first_project/data/plant_purchases.csv". The configuration information for this data file, and all data files, should be specified in data_import.json. For our example, this file looks like,

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

Note that the field "optional" is not yet used.

You may optionally set any of the following arguments for `install_data`:
```julia
function install_data(project_name::String; scenario::AbstractString="default",
                      dbname::Symbol=:default, create_db::Bool=true, 
                      overwrite::Bool=true, via_sdk::Bool=false)
```

The optional arguments are:

- scenario: String name of a scenario specified in projects.json.
- dbname: Name for the database. This will create a new database if it does not yet exist. If set to `:default`, the database will be named `:$(project name)_$(scenario)`. In the example case, `:my_first_project_default`.
- create_db: If true, create a new database if dbname does not exist.
- overwrite: If true, overwrite database specified by dbname.
- via_sdk: If true, use the Julia SDK to populate the data. If false, use the Rel native.

### Load data from a single file

This is not yet exposed in deploy.jl.

### Install relations for a scenario

As with installing data, the only information you must provide is the project name. The scenario will default to "default". Every project should include a default scenario in `project.json`.

```julia
julia> install_scenario("my_first_project")
```

In the example, project.json specifies just one Rel file, "purchase_insights" (see contents of project.json above). The function `install_scenario` will expect this file to be located at "projects/my_first_project/src/purchase_insights.rel".

You may optionally set any of the following arguments for `install_scenario`:
```julia
function install_scenario(project_name::String; scenario::AbstractString="default",
                    dbname::Symbol=:default, sequential::Bool=false)
```

The optional arguments are:

- scenario: String name of a scenario specified in projects.json.
- dbname: Name for the database. This will create a new database if it does not yet exist. If set to `:default`, the database will be named `:$(project name)_$(scenario)`. In the example case, `:my_first_project_default`.
- sequential: If true, each .rel file will be installed sequentially in the order that it appears in the project config. If false, all .rel files will be joined as a single program and installed in a single transaction.