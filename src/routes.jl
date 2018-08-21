
|(x::String, y::String)="$x|$y"

GET="GET"
POST="POST"
PUT="PUT"
DELETE="DELETE"
HEAD = "HEAD"
OPTIONS = "OPTIONS"
PATCH = "PATCH"

function NotFound(q,req,res)
  res.status = 404
  return notfound_message
end

routes=Dict()
routes_patterns=Dict()
routes["notfound"] = NotFound

function createurl(url::String,funtion::Function)
  if occursin(":",url)||occursin("(",url)
    try
      url_ = "^"*url*"\$"
      url_ = replace(url_,":" => "(?<")
      url_ = replace(url_,">" => ">[a-z]+)")
      routes_patterns[Regex(url_)] = funtion
      @info("Url added",Regex(url_))
    catch
     @warn("Error in the format of the route $url, verify it\n \"VERB/get/:data>\" \n \"VERB/get/([0-9])\"")
    end
  else
    routes[url] = funtion
    @info("Url added",url)
  end
end

macro page(exp1,exp2)
  quote
    createurl("GET"*$exp1,(q,req,res)->$exp2)
  end
end

macro route(exp1,exp2,exp3)
  quote
    verbs= split($exp1,"|")
    for i=verbs
      createurl(i*$exp2,(q,req,res)->$exp3)
    end
  end
end

function Get(URL::String, fun::Function)
  createurl("GET"*URL,fun)
end

function Post(URL::String, fun::Function)
  createurl("POST"*URL,fun)
end

function Put(URL::String, fun::Function)
  createurl("PUT"*URL,fun)
end

function Delete(URL::String, fun::Function)
  createurl("DELETE"*URL,fun)
end
