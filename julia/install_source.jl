include("./install_data.jl")

# -- Get meta data from json config files -- 

function get_source_path(file_name::AbstractString,
                         project_path::AbstractString)
    # File path for Rel source files
    file_path = "$(project_path)/src/$(file_name).rel"
    return file_path
end

function project_source_filelist(project_name::AbstractString; 
                                 scenario::AbstractString="default")
    
    # Parse JSON configuration file for project
    project_path = get_project_path(project_name)
    config_path = "$(project_path)/config/project.json"
    # Get data files associated with scenario
    return parsefile(config_path)[scenario]["deps"]

end

# -- Helper functions to link rel source files

function load_src(file_name::AbstractString, 
                  project_path::AbstractString)

    # Set path to rel file
    file_path = get_source_path(file_name,project_path)
    
    # Get source content as string
    contents = read(file_path, String)
    
    # Return with comments indicating source file
    "/* - Start of linked file: $(file_name) - */\n" *
    contents *
    "/* ----- End of linked file: $(file_name) ----- */\n"
end

# -- Call these functions to load rel source files

function install_src_file(conn::LocalConnection,
                          file_name::AbstractString, 
                          project_path::AbstractString)
    
    # Set path to rel file
    file_path = get_source_path(file_name,project_path)
    # Install the file
    @info "Installing $(file_name).rel at $(file_path)..."
    install_source(conn; path=file_path, name=file_name)
    @info "...Success."
end

function install_rel(conn::LocalConnection,
                     rel_string::AbstractString; 
                     name::AbstractString="source")

    # Install the file
    @info "Installing $(name)..."
    install_source(conn, name, rel_string)
    @info "...Success."
end

function install_scenario_src(conn::LocalConnection, project_name::AbstractString; 
                              scenario::AbstractString="default", sequential::Bool=false)

    # Load all source files for the scenario

    # Determine which source files belong to the scenario
    src_file_names = project_source_filelist(project_name; scenario=scenario)

    # Get project path
    project_path = get_project_path(project_name)

    @info "Installing source files for scenario '$(scenario)' in project '$(project_name)'."

    if sequential
        # Install sequentially, in order determined by config file
        @info "Rel source installation in sequential mode."
        for src_file in src_file_names
            install_src_file(conn,src_file,project_path)
        end
    else
        # Install as single source
        @info "Rel source installation in single-source mode."
        rel = ""
        for src_file in src_file_names
            rel = rel * load_src(src_file,project_path)
        end
        install_rel(conn,rel;name="$(project_name)_$(scenario)")
    end
end