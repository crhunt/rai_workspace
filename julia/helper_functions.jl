# -- Get full paths from names (project name and scenario) --

function get_project_path(project_name::AbstractString)
    
    # Turn project name string into full rel path
    project_path = "$(pwd())/projects/$(project_name)"
    return project_path
end

function get_source_path(file_name::AbstractString,
                         project_path::AbstractString)
    # File path for Rel source files
    occursin(".rel", file_name) ? file_path = "$(project_path)/src/$(file_name)" : 
                                  file_path = "$(project_path)/src/$(file_name).rel"
    return file_path
end

function get_data_path(file_name::AbstractString,
                       project_path::AbstractString)
# File path for Rel source files
file_path = "$(project_path)/data/$(file_name)"
return file_path
end

# -- Helper function to link rel source files

function load_src(file_name::AbstractString, 
                  project_path::AbstractString)

# Set path to rel file
file_path = get_source_path(file_name,project_path)

# Get source content as string
contents = read(file_path, String)

# Return with comments indicating source file
"/* - Start of linked file: $(file_name) - */\n" *
contents *
"\n/* ----- End of linked file: $(file_name) ----- */\n"
end