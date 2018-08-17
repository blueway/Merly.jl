using Merly
using Test

# write your own tests here
server = Merly.app()
@page "/" "Hello World!"
@page "/json"  Dict("msg" =>"Hello World!")
@route GET "/get/:data>" begin
  println("params: ",q.params["data"])
  "get this back: {{data}}"
end

server.start()
@test server.useCORS(true) == true

@test server.notfound("<!DOCTYPE html>
              <html>
              <head><title>Not found</title></head>
              <body><h1>404, Not found</h1></body>
              </html>") == "<!DOCTYPE html>
              <html>
              <head><title>Not found</title></head>
              <body><h1>404, Not found</h1></body>
              </html>"

@test @page "/" "Hello World!" == "GET/"



#=@test Post("/data/:nombre>", (q,req,res)->(begin
         println("body: ",q.body)
         res.headers["Content-Type"]="text/plain"

         "I did something!"
end)) =="GET/get/:nombre>"


@test @route POST|PUT|DELETE "/" begin
         res.headers["Content-Type"]="text/plain"
         "I did something!"
       end == "POST/
               PUT/
               DELETE/"=#
