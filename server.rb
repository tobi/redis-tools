require 'queue'

queue = Queue.new("testing")
queue.clear

loop do
  queue.push 1
  puts queue.size
end
