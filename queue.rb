require 'rubygems'
require 'redis'
require 'digest/md5'
#require 'msgpack'

$redis = Redis.new

# Performance: ~ 2100 messages per second on i7 iMac
class Queue
  
  def initialize(name)
    @queue_name = "queue:#{name}"    
  end
  
  def clear
    $redis.del(@queue_name)
  end
  
  def size
    $redis.llen(@queue_name)
  end
  
  def push(object)
    hash = Digest::MD5.hexdigest(object.to_s)
    $redis.set("msg:#{hash}", MessagePack.pack(object))
    $redis.rpush(@queue_name, hash)
  end
  
  def subscribe
    loop do            
      hash = $redis.blpop(@queue_name, 0)[1]
      object = $redis.get("msg:#{hash}")
      if object
        begin
          yield MessagePack.unpack(object)
          # Done, remove message from redis. 
          $redis.del("msg:#{hash}")
        rescue
          # Error, add the message again to the end of the queue
          $redis.rpush(@queue_name, hash)
          raise
        end      
      end
    end    
  end
end
  
