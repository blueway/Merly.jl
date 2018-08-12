VERSION >= v"1.0.0" 
__precompile__()
module Merly
import Base.|

using Sockets,
JSON,
HTTP,
XMLDict

include("mimetypes.jl")
include("routes.jl")
include("allformats.jl")
include("webserver.jl")

bytes(s::String) = Vector{UInt8}(s)
export bytes,app, @page, @route, GET,POST,PUT,DELETE,HEAD,OPTIONS,PATCH,Get,Post,Put,Delete

cors=false::Bool
middles=[]
root=pwd()
if root[end]=='/'
    root=root[1:end-1]
elseif Sys.iswindows() && root[end]=='\\'
    root=root[1:end-1]
end

exten="\"\""::AbstractString

mutable struct Data
    query::Dict
    params::Any
    body::Any
    headers::Dict
end
global notfound_message = bytes(
                                JSON.json(Dict("code" => 404,"msg" =>"NOT FOUND")) 
                               )
global q=Data(Dict(),"","",Dict())

mutable struct Fram
    notfound::Function
    start::Function
    useCORS::Function
    use::Function
    webserverfiles::Function
    webserverpath::Function
end

function _body(data::Array{UInt8,1},format::SubString{String})
    return getindex(formats, format)(String(data))
end

function File(file::String)
    try
        path = normpath(root, file)
        return String(read(path))
    catch
        return file
    end
end

function resolveroute(ruta::String)
    for key in keys(routes_patterns)
        params= match(key,ruta)
        if params!= nothing
            return params, getindex(routes_patterns,key)
        end
    end
end

function processroute_pattern(searchroute::String,request,response)
    q.params, _function  = resolveroute(searchroute)
    respond = _function(q,request,response)
    sal = collect((m.match for m = eachmatch(Regex("{{([a-z])+}}"), respond)))
    for i in sal
        respond = replace(respond,Regex(i) => q.params["$(i[3:end-2])"])
    end
    response.status = 200
    return respond
end

function handler(request::HTTP.Messages.Request)
    data = split(request.target,"?")
    url=data[1]
    searchroute = request.method*url
    try
        q.query= HTTP.queryparams(data[2]);
    catch
    end
    response = HTTP.Response()

    try
        q.body= _body(request.body,HTTP.header(request, "Content-Type"))
    catch err
        q.body = _body(request.body,SubString("*/*"))
    end

    if cors
        HTTP.setheader(response,"Access-Control-Allow-Origin" => "*")
        HTTP.setheader(response,"Access-Control-Allow-Methods" => "POST,GET,OPTIONS")
    end

    HTTP.setheader(response,"Content-Type" => "text/plain" )
    body = ""
    try
        response.status= 200
        body = getindex(routes, searchroute)(q,request,response)
    catch
        try
            body = processroute_pattern(searchroute,request,response)
        catch
            getindex(routes, "notfound")(q,request,response)
        end
    end
    if isa(body,Dict) 
        body = JSON.json(body)
        HTTP.setheader(response,"Content-Type" => "application/json" )
    end
    response.body = bytes(body)
    if length(middles)  > 0
        for middle in middles
            middle(q,request,response)
        end
    end


    for (key, value) in q.headers
        HTTP.setheader(response,key => value )
    end


    return response
end


function app()
    global root
    global exten
    global cors
    global middles
    function useCORS(activate::Bool)
        cors=activate
    end
    function use(middle::Function)
        push!(middles ,middle)
    end
    function notfound(text::AbstractString)
        notfound_message= File(text)
    end

    function webserverfiles(load::AbstractString)
        if load=="*"
            WebServer(root)
        else
            exten=load::AbstractString
            WebServer(root)
        end
    end

    function webserverpath(path::AbstractString)
        root= path
    end

    function start(config=Dict("host" => "127.0.0.1","port" => 8000)::Dict)
        host= Sockets.IPv4("127.0.0.1")
        port= 8000

        try
            host=Sockets.IPv4(get(config, "host", "127.0.0.1")::AbstractString)
        catch
            try
                host=Sockets.IPv6(get(config, "host", "127.0.0.1")::AbstractString)
            catch
            end
        end

        try
            port=get(config, "port", 8000)::Int
        catch
            @info("Port 8000 ")
        end

        http = (req)-> handler(req)

        myserver= HTTP.Servers.Server(http, stdout)

        try
            #@async run(server, host=IPv4(host), port=port)
            HTTP.Servers.serve(myserver, host, port)
        catch
            try
                HTTP.Servers.serve(myserver, host, port)
            catch
                @warn("Address not valid, check it")
            end
        end
    end
    return Fram(notfound,start,useCORS,use,webserverfiles,webserverpath)
end
end # module
#HSTS     HTTP.setheader(response,"Strict-Transport-Security" => "max-age=10886400; includeSubDomains; preload"
