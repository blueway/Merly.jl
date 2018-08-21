using Merly
using Test
using HTTP
using JSON

# write your own tests here
server = Merly.app()
@page "/" "Hello World!"
@page "/json"  Dict("msg" =>"Hello World!")
@route GET "/get/:data>" begin
  println("params: ",q.params["data"])
  "get this back: {{data}}"
end

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


Post("/data", (q,req,res)->(begin
  println("params: ",q.params)
  println("query: ",q.query)
  println("body: ",q.body)
  q.headers["Content-Type"]= "text/plain"
  "I did something!"
end))

@async server.start()

sleep(2)

myjson = Dict("query"=>"data")
my_headers = HTTP.mkheaders(["Accept" => "application/json","Content-Type" => "application/json"])
r = HTTP.post("http://localhost:8000/data",my_headers,JSON.json(myjson))
@test r.status == 200
@test String(r.body) == "I did something!"

