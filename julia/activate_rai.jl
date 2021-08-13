# Determine from args whether to use binary server, external server, or local RAI repo.
import Pkg

if @isdefined args
    use_binary = args["binary-server"]
    use_external_server = args["external-server"]
else
    use_binary = "--binary-server" in ARGS
    use_external_server = "--external-server" in ARGS
end

if ! (use_binary || use_external_server)
    println("Load RAI...")
    Pkg.activate((ENV["RAI_PATH"]))
    using RAI.Server
    import RAI.API: CSVString, JSONString
end

using RelationalAI

include("./rai_server.jl")
startup_server()