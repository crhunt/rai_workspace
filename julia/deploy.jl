using DataFrames
import RelationalAITypes

include("./insert_data.jl")
include("./install_source.jl")

global current_conn = missing
global current_project = ""
global current_scenario = "default"
global current_dbname = :default

# -- Used internally --

function get_db_conn(dbname::Symbol=:default)
    # Create local connection 
    # TO DO: Add report argument for reporting
    if ! isequal(current_mgmt_conn,missing)
        conn = CloudConnection(management_conn=current_mgmt_conn, dbname=dbname, compute_name=Symbol(current_compute_name))
    else
        conn = LocalConnection(dbname=dbname)
    end
end

function set_dbname(dbname::Symbol, 
                    project_name::AbstractString,
                    scenario::AbstractString)
    # Set db name
    if dbname == :default
        dbname = Symbol("$(project_name)_$(scenario)")
        @info "Set current database name to :$(project_name)_$(scenario)"
    end
    return dbname
end

function set_connection(dbname::Symbol)
    global current_conn = get_db_conn(dbname)
end

# -- Set the database --

function set_project(project_name::String; scenario::AbstractString="default",
                     dbname::Symbol=:default, create_db::Bool=true, 
                     overwrite::Bool=true)
    # Set db name
    global current_dbname = set_dbname(dbname, project_name, scenario)

    # Get connection from db name
    global current_conn = get_db_conn(current_dbname)
    global current_project = project_name
    global current_scenario = scenario

    println("Set project to: $(current_project)")
    println("Set scenario to: $(current_scenario)")
    println("Set database for project/scenario to: :$(current_dbname)")
    
    # Recreate DB
    if create_db || overwrite
        create_database(current_conn; overwrite=overwrite)
        overwrite ? println("Database created with dbname: :$(current_dbname)\nDatabase :$(current_dbname) overwritten.") : 
                    println("Database created with dbname: $(current_dbname)")
    end

end

function check_conn(project_name::String, scenario::AbstractString,
                    dbname::Symbol)
    # Check overrides on global settings
    if dbname != :default
        conn = get_db_conn(dbname)
    elseif project_name != current_project
        # Set db name
        dbname = set_dbname(dbname, project_name, scenario)
        # Get connection from db name
        conn = get_db_conn(dbname)
    else
        dbname = current_dbname
        conn = current_conn
    end

    if isequal(conn,missing)
        @error "No database connection found.\nSet with set_project(project_name). See readme for details."
        return conn
    end

    println("Connection set to database: :$(dbname)")

    return conn
end

# -- Install EDB --

function insert_data(; project_name::String=current_project, 
                      scenario::AbstractString=current_scenario,
                      dbname::Symbol=current_dbname, create_db::Bool=false, 
                      overwrite::Bool=true)

    # Check overrides on global settings
    conn = check_conn(project_name,scenario,dbname)
    
    # Recreate DB
    if create_db 
        create_database(conn; overwrite=overwrite)
        overwrite ? println("Database overwritten.") : println("Database created.")
    end

    # Install data
    insert_scenario_data(conn, project_name; scenario=scenario)
end

# -- Install IDB --

function install_scenario(; project_name::String=current_project, 
                          scenario::AbstractString=current_scenario,
                          dbname::Symbol=current_dbname, sequential::Bool=false)
    
    # Check overrides on global settings
    conn = check_conn(project_name,scenario,dbname)

    # Install Rel files
    install_scenario_src(conn, project_name; 
                         scenario=scenario, sequential=sequential)
end

function reinstall_scenario(; project_name::String=current_project, 
                            scenario::AbstractString=current_scenario,
                            dbname::Symbol=current_dbname, sequential::Bool=false)

    # Check overrides on global settings
    conn = check_conn(project_name,scenario,dbname)

    # Install Rel files
    reinstall_scenario_src(conn, project_name; 
                           scenario=scenario, sequential=sequential)
end

function list_scenario_source(; project_name::String=current_project, 
                              scenario::AbstractString=current_scenario,
                              dbname::Symbol=current_dbname)
    
    # Check overrides on global settings
    conn = check_conn(project_name,scenario,dbname)
    # List sources
    list_source(conn)
end

# -- Query scenario --

function pretty_print_query(relations::Array{Symbol}, results::RelationalAITypes.RelDict{Any})

    # Filter out unrelated
    rel_names = Set(relations)
    rez = filter(p -> first(p).name in rel_names, results)

    # Create a map 
    rel_map = Dict()
    for (rel, contents) in rez
        rel_list = get(rel_map, rel.name, [])
        push!(rel_list, (rel, contents))
        push!(rel_map, rel.name => rel_list)
    end

    for rel_list in values(rel_map)
        for (rel_key, rel_contents) in rel_list
            println("""
            \n>>> Showing contents of :$rel_key
            $(DataFrame(rel_contents))
            """)
        end
    end

end

function query_scenario(relations::Array{Symbol}; 
                        project_name::String=current_project,
                        scenario::AbstractString=current_scenario,
                        dbname::Symbol=current_dbname,
                        rel::AbstractString="",
                        from_file::String="")
    
    # Check overrides on global settings
    conn = check_conn(project_name,scenario,dbname)

    # Get query from a file
    if length(from_file) > 0
        project_path = get_project_path(project_name)
        rel = rel * "\n" * load_src(from_file, project_path)
    end

    # Perform the query
    results = query(conn, rel; outputs=relations)
    @info "Query successful."

    pretty_print_query(relations, results)

end

function replace_relation(relation_name::Symbol,
                          new_definition::String;
                          old_args::Array{Any}=[], new_args::Array{Any}=[],
                          project_name::String=current_project,
                          scenario::AbstractString=current_scenario,
                          dbname::Symbol=current_dbname)

    # Check overrides on global settings
    conn = check_conn(project_name,scenario,dbname)

    # Strings from arguments
    length(old_args) > 0 ? old_arg_rel = "(" * join(old_args,",") * ")" : old_arg_rel = ""
    length(new_args) > 0 ? new_arg_rel = "(" * join(new_args,",") * ")" : new_arg_rel = ""

    # Create update string
    update_rel = """
        def delete[:$(String(relation_name))]$(old_arg_rel) = $(String(relation_name))$(old_arg_rel)
        def insert[:$(String(relation_name))]$(new_arg_rel) = $(new_definition)
        """
    println("Rel code for update:\n$(update_rel)")

    # Execute query
    results = query(conn, update_rel; readonly=false, outputs=[relation_name])
    @info "Update successful."

    pretty_print_query([relation_name], results)

end

println("Including deploy.jl")