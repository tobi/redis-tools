STDOUT.sync = true

require 'queue'

start_time = Time.now.to_i
msg = 0


queue = Queue.new("testing")
puts "Waiting: #{queue.size}"

queue.subscribe do |obj|
  msg += 1
  p obj
  seconds = Time.now.to_i - start_time
  puts "%.3f ... " % [msg.to_f / seconds]
end