# import DataFrames: DataFrame
# import Dates: Date, DateTime
# import RelationalAI: CSVFile, CSVFileSyntax
# import RelationalAIProtocol: JSONString
import JSON: json, parsefile
# using RelationalAITypes: Integration

# -- Get full paths from names (project name and scenario) --

function get_project_path(project_name::AbstractString)
    
    # Turn project name string into full rel path
    project_path = "$(pwd())/projects/$(project_name)"
    return project_path
end

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
    file_path = "$(project_path)/data/$(file_name)" # Path to data file
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

function install_scenario_data(conn::LocalConnection, project_name::AbstractString; 
                               scenario::AbstractString="default", via_sdk::Bool=false)

    # Load all data files for a scenario

    # Get configuration for data files
    file_config = data_import_configuration(project_name)

    # Determine which data files belong to the scenario
    data_file_names = project_data_filelist(project_name; scenario=scenario)

    # Get project path
    project_path = get_project_path(project_name)

    @info "Installing data for scenario '$(scenario)' in project '$(project_name)'."
    
    # Load each file
    if via_sdk
        # Use Julia SDK to install data
        @info "Installing via SDK."
        for file_name in data_file_names
            file_path = "$(project_path)/data/$(file_name)"
            @info "Installing $(file_name) at $(file_path)..."
            install_source(conn; path=file_path, name=file_config[file_name]["rel"])
            @info "...Success."
        end
    else
        # Use Rel to install data
        @info "Installing via Rel."
        for file_name in data_file_names
            # Create Rel code for import
            @info "Installing $(file_name)..."
            rel_code_string = generate_import_schema_rel(file_name,file_config,project_path)
            # Install using Rel
            query(conn, rel_code_string; readonly=false)
            @info "...Success."
        end
    end

    @info "Project data installed."

end

function install_data_file(conn::LocalConnection,
                           file_name::AbstractString, 
                           project_name::AbstractString)

    # Install data from any single file in any project
    # The project name should be the source project for the data file

    @info "Installing via Rel."
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