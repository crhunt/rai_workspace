# Creates a local RAI server

if use_binary
    function startup_server()
        # To use tracing:
        # run(`bash -c "rai-server server --tracing print &"`)
        run(`bash -c "rai-server server --profile functions &"`)
        # run(`bash -c "rai-server server &"`)
        sleep(5)
    end
    shutdown_server() = run(`pkill rai-server`)
elseif use_external_server
    startup_server() = nothing
    shutdown_server() = nothing
else
    # To use tracing:
    # rai_server = RAIServer(Server.Configuration(; tracing=:print ))
    rai_server = RAIServer(Server.Configuration(; profile=:functions ))
    startup_server() = @async start!(rai_server)
    shutdown_server() = stop!(rai_server)
end