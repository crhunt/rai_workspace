import Pkg
using RelationalAI
using RelationalAIManagement
using Dates

# Parse arguments to determine whether:
# 1. (default): A remote server
# 2. binary-server: A local server using the raicode binary
# 3. local-server: A local server using a local raicode repo

global current_server_type = "remote-server"
global current_mgmt_conn = missing
#global current_compute_name = "rai-workspace-xs"
global current_compute_name = "rai-workspace-$(string(today()))-xs"

binary_server = "binary-server"
remote_server = "remote-server"
local_server = "local-server"

function set_server(server_type::String;
                    profile::AbstractString="default",
                    compute_name::AbstractString=current_compute_name)
    
    global current_server_type = server_type

    if ( current_server_type == local_server || current_server_type == binary_server )
        include("julia/local_server.jl")
        global current_mgmt_conn = missing
        startup_server()
    elseif current_server_type == remote_server
        # Verify SSL? Yes if default profile
        verify_ssl = profile === "default" ? true : false
        # Set management connection
        global current_mgmt_conn = ManagementConnection(; profile=profile, verify_ssl=verify_ssl)
        # Set global compute name
        global current_compute_name = compute_name
        # Print status
        println("Profile: $(profile)")
        println("Verify SSL: $(verify_ssl)")
        println("Compute name: $(current_compute_name)")
        accounts = join( Set( [String(x.account_name) for x in list_users(current_mgmt_conn)] ), ", " )
        println("Account(s): $(accounts)")
        computes = join( [String(x.name) for x in list_computes(current_mgmt_conn) if isequal(x.state,:PROVISIONED)], ", " )
        println("Provisioned computes: $(computes)")
        if !occursin(current_compute_name,computes)
            @warn "Compute $(current_compute_name) not found in provisioned computes."
        end
    else
        @warn "Server type not recognized. Specify: 'binary-server', 'local-server', or 'remote-server'."
    end

end

"""
function shutdown_server()
    if current_server_type == "binary-server"
        run(`pkill rai-server`)
    elseif current_server_type == "local-server"
        rai_server = RAIServer(Server.Configuration(; profile=:functions ))
        stop!(rai_server)
    end
end
"""

println("Including activate_rai.jl")