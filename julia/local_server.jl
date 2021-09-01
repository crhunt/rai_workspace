using RAI.Server
import RAI.API: CSVString, JSONString


if current_server_type == "binary-server"
    function startup_server()
        # To use tracing:
        # run(`bash -c "rai-server server --tracing print &"`)
        run(`bash -c "rai-server server --profile functions &"`)
        # run(`bash -c "rai-server server &"`)
        sleep(5)
    end
    shutdown_server() = run(`pkill rai-server`)
elseif current_server_type == "local-server"
    println("Load RAI...")
    Pkg.activate((ENV["RAI_PATH"]))
    # To use tracing:
    # rai_server = RAIServer(Server.Configuration(; tracing=:print ))
    rai_server = RAIServer(Server.Configuration(; profile=:functions ))
    startup_server() = @async start!(rai_server)
    shutdown_server() = stop!(rai_server)
else
    startup_server() = nothing
    shutdown_server() = nothing
end

startup_server()