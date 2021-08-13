using DataFrames
import RelationalAITypes

include("./install_data.jl")
include("./install_source.jl")

function get_db_conn(dbname::Symbol=:default)
    # Create local connection 
    # TO DO: Add report argument for reporting
    conn = LocalConnection(dbname=dbname)
end

function set_dbname(dbname::Symbol, 
                    project_name::AbstractString,
                    scenario::AbstractString)
    # Set db name
    if dbname == :default
        dbname = Symbol("$(project_name)_$(scenario)")
        @info "Database name set to :$(project_name)_$(scenario)"
    end
    return dbname
end

function install_data(project_name::String; scenario::AbstractString="default",
                      dbname::Symbol=:default, create_db::Bool=true, 
                      overwrite::Bool=true, via_sdk::Bool=false)

    # Set db name
    dbname = set_dbname(dbname, project_name, scenario)

    # Get connection from db name
    conn = get_db_conn(dbname)
    
    # Recreate DB
    create_db && create_database(conn; overwrite=overwrite)

    # Install data
    install_scenario_data(conn, project_name; scenario=scenario, via_sdk=via_sdk)
end

function install_scenario(project_name::String; scenario::AbstractString="default",
                    dbname::Symbol=:default, sequential::Bool=false)
    
    # Set db name
    dbname = set_dbname(dbname, project_name, scenario)

    # Get connection from db name
    conn = get_db_conn(dbname)

    # Install Rel files
    install_scenario_src(conn, project_name; 
                         scenario=scenario, sequential=sequential)
end

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

function query_scenario(relations::Array{Symbol}, project_name::String; 
                        scenario::AbstractString="default",
                        rel::AbstractString="",
                        dbname::Symbol=:default)
    
    # Set db name
    dbname = set_dbname(dbname, project_name, scenario)

    # Get connection from db name
    conn = get_db_conn(dbname)

    # Perform the query
    results = query(conn, rel; outputs=relations)
    @info "Query successful."

    pretty_print_query(relations, results)

end

println("Including deploy.jl")