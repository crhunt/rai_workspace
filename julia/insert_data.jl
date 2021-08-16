# import DataFrames: DataFrame
# import Dates: Date, DateTime
# import RelationalAI: CSVFile, CSVFileSyntax
# import RelationalAIProtocol: JSONString
import JSON: json, parsefile
include("./helper_functions.jl")

# using RelationalAITypes: Integration

# -- Get meta data from json config files --

function data_import_configuration(project_name::AbstractString)

    # Parse JSON configuration file for all data files
    project_path = get_project_path(project_name)
    config_path = "$(project_path)/config/data_import.json"
    return parsefile(config_path)

end

function project_data_filelist(project_name::AbstractString; 
                               scenario::AbstractString="default")
    
    # Parse JSON configuration file for project
    project_path = get_project_path(project_name)
    config_path = "$(project_path)/config/project.json"
    # Get data files associated with scenario
    return parsefile(config_path)[scenario]["data"]

end

# -- Create the Rel code necessary to install a file --

function generate_import_schema_rel(file_name::AbstractString,
                                    file_config::AbstractDict,
                                    project_path::AbstractString)
    
    # Create the rel code for importing the data
    rel = ""
    file_path = get_data_path(file_name, project_path) # Path to data file
    file_rel_name = file_config[file_name]["rel"]   # Rel name for data file
    rel = rel * """
        def insert[:$(file_rel_name)] = load_csv[config_$(file_rel_name)] // Insert the data
        def config_$(file_rel_name)[:path] = "$(file_path)"              // Path to data
        """
    for col in file_config[file_name]["columns"]
        rel = rel * """
            def config_$(file_rel_name)[:schema,:$(col["name"])] = "$(col["type"])" // Data type for column
            """
    end

    return rel
end

# -- Call these functions to load data --

function insert_scenario_data(conn::LocalConnection, project_name::AbstractString; 
                              scenario::AbstractString="default")

    # Load all data files for a scenario

    # Get configuration for data files
    file_config = data_import_configuration(project_name)

    # Determine which data files belong to the scenario
    data_file_names = project_data_filelist(project_name; scenario=scenario)

    # CSV files
    csv_file_names = [x for x in data_file_names if occursin(".csv", x)]
    # REL files
    rel_file_names = [x for x in data_file_names if occursin(".rel", x)]

    # Get project path
    project_path = get_project_path(project_name)

    @info "Inserting data for scenario '$(scenario)' in project '$(project_name)'."
    
    # Load each file

    # Install CSV files
    @info "Inserting CSV files via query (update mode)."
    for file_name in csv_file_names
        # Create Rel code for import
        @info "Inserting $(file_name) from $(project_name)..."
        rel_code_string = generate_import_schema_rel(file_name,file_config,project_path)
        # Install using Rel
        query(conn, rel_code_string; readonly=false)
        @info "...Success."
    end

    # Installing REL files
    @info "Inserting REL files via query (update mode)."
    rel_code_string = ""
    for file_name in rel_file_names
        file_path = get_source_path(file_name,project_path)
        @info "Adding $(file_name) from $(project_name)..."
        rel_code_string = rel_code_string * load_src(file_name, project_path)
        @info "...Success."
    end
    @info "Inserting all data relations..."
    query(conn, rel_code_string; readonly=false)
    @info "...Success."

    @info "Project data inserted."

end

function insert_data_file(conn::LocalConnection,
                           file_name::AbstractString, 
                           project_name::AbstractString)

    # Install data from any single file in any project
    # The project name should be the source project for the data file

    @info "Inserting via query (update mode)."
    @info "Installing $(file_name) from project '$(project_name)'..."

    # Get configuration for data files
    file_config = data_import_configuration(project_name)
    # Get project path
    project_path = get_project_path(project_name)
    # Create Rel code for import
    rel_code_string = generate_import_schema_rel(file_name,file_config,project_path)
    # Install using Rel
    query(conn, rel_code_string; readonly=false)

    @info "...Success."

end