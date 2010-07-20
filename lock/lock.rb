require 'rubygems'
require 'redis'
require 'digest/md5'
require 'active_support'

$redis = Redis.new

class Lock
  class Error < StandardError
  end
  
  def self.acquire(key, lock_time = 1.second)    
    start_time = Time.now.to_i
    loop do 
      now = Time.now.to_i
      
      if $redis.setnx(key, now + lock_time)
        begin
          yield
          return
        ensure
          $redis.del(key)
        end
      
      else
        time = $redis.get(key)
        if time.to_i < now
          if $redis.getset(key, now + lock_time) == time           
            $redis.del(key)
          end
        else                    
          
          # Give up after 3x lock_time
          if now > start_time + (lock_time * 3) 
            raise Error, 'could not aquire lock'
          end
          sleep 0.001
        end         
      end          
    end
  end
end
 