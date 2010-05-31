require 'rubygems'
require 'redis'
require 'digest/md5'
require 'msgpack'

$redis = Redis.new

# By default it uses 60 secs intervals and keeps 10 unique buckets. 
# This is useful for example for a chat buddy list, allows you to keep presence of all the 
# people who are online by periodically adding their user ids to the presence class when they
# do http calls to you. 
class Presence
 
  def initialize(name, seconds = 60, buckets = 10)
    @name = name
    @seconds = seconds
    @buckets = buckets
  end
  
  def clear
    @buckets.times do |num|
      $redis.del "#{@name}:#{num-1}"
    end
  end
  
  def clear_older_then(num)
    @buckets.downto(num+1) do |num|
      $redis.del "#{@name}:#{recent_bucket_num(num-1)}"
    end
  end
      
  def add(token, time = Time.now.to_i)
    $redis.sadd "#{@name}:#{recent_bucket_num(0, time)}", token 
  end
  
  def present_in_buckets(number_of_buckets)
    time = Time.now.to_i
    
    keys = (1..number_of_buckets).collect do |times|
      "#{@name}:#{recent_bucket_num(times - 1)}"
    end
        
    if keys.size > 1 
      $redis.sunion(keys)    
    else
      $redis.smembers(keys.first)    
    end
  end
  
  private 
  
  def recent_bucket_num(num = 0, time = Time.now.to_i)
    seconds_in_segment = time % (@buckets * @seconds)
    closest_matching_bucket = seconds_in_segment / @seconds
    
    return (closest_matching_bucket - num) % @buckets
  end  
  
end

require "test/unit"

class TestLibraryFileName < Test::Unit::TestCase
  
  def test_active_in_one_bucket
    a = Presence.new("test")    
    a.clear
    a.add 1
    a.add 2
    a.add 3
    assert_equal ["1","2","3"], a.present_in_buckets(1).sort    
  end
  
  def test_active_in_more_then_one_bucket
    require 'active_support'
    a = Presence.new("test")    
    a.clear
    a.add 1, 2.minutes.ago.to_i
    a.add 2
    a.add 3
    assert_equal ["2","3"], a.present_in_buckets(1).sort    
    assert_equal ["1","2","3"], a.present_in_buckets(5).sort    
  end
  
  def test_clear_oder_then
    a = Presence.new('clearing')
    a.clear
    (0..9).each do |num|
      $redis.sadd "clearing:#{num}", "DATA"      
    end
    a.clear_older_then(5)
    assert_equal ['DATA'], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 0)}")
    assert_equal ['DATA'], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 1)}")
    assert_equal ['DATA'], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 2)}")
    assert_equal ['DATA'], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 3)}")
    assert_equal ['DATA'], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 4)}")
    assert_equal [], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 5)}")
    assert_equal [], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 6)}")
    assert_equal [], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 7)}")
    assert_equal [], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 8)}")
    assert_equal [], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 9)}")
    assert_equal ['DATA'], $redis.smembers("clearing:#{a.send(:recent_bucket_num, 10)}")
    
    
  end
 
    
  
  def test_recent_bucket
    require 'time'
    time = Time.parse("2010-05-30 14:55").to_i
    
    a = Presence.new("test")    
    a.clear
    assert_equal 5, a.send(:recent_bucket_num,0, time)
    assert_equal 4, a.send(:recent_bucket_num,1, time)
    assert_equal 3, a.send(:recent_bucket_num,2, time)
    assert_equal 2, a.send(:recent_bucket_num,3, time)
    assert_equal 1, a.send(:recent_bucket_num,4, time)
    assert_equal 0, a.send(:recent_bucket_num,5, time)
    assert_equal 9, a.send(:recent_bucket_num,6, time)
    assert_equal 8, a.send(:recent_bucket_num,7, time)
    assert_equal 7, a.send(:recent_bucket_num,8, time)
    assert_equal 6, a.send(:recent_bucket_num,9, time)
    assert_equal 5, a.send(:recent_bucket_num,10, time)
    assert_equal 4, a.send(:recent_bucket_num,11, time)
    assert_equal 3, a.send(:recent_bucket_num,12, time)
    assert_equal 2, a.send(:recent_bucket_num,13, time)
    assert_equal 1, a.send(:recent_bucket_num,14, time)
    assert_equal 0, a.send(:recent_bucket_num,15, time)
    assert_equal 9, a.send(:recent_bucket_num,16, time)    
  end
end
