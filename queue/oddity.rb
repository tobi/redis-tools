require 'rubygems'
require 'redis'


server = Redis.new

puts "Pushing 1000 elements in array"
1000.times do |i|
  server.lpush 'q', i
end
server.send(:disconnect)  

client = Redis.new
p client.llen 'q'

loop do 
  p client.blpop('q', 0).last
end
