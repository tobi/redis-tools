require "test/unit"

require File.dirname(__FILE__) + "/lock"

class TestLock < Test::Unit::TestCase
  def setup
    $redis.flushall
  end
  
  def test_lock    
    run = false
    Lock.acquire 'a' do
      run = true
    end
    
    assert run
  end
  
  def test_expired_lock_is_overtaken    
    $redis['a'] = 5.minutes.ago.to_i
    
    run = false
    Lock.acquire 'a' do
      run = true
    end    
    assert run        
  end
  
  def test_cannot_get_lock
  
    $redis['b'] = 5.minutes.from_now.to_i
    
    assert_raise(Lock::Error) do
      Lock.acquire 'b' do
        raise 'should not happen'
      end    
    end
  end
  
  def test_lock_exclusive_access
    
    run = false
    
    results = []
    
    a = Thread.new do
      Lock.acquire('a', 1.minute) do
        sleep 5
        results << 'first'
      end    
    end
    
    b = Thread.new do
      sleep 1

      Lock.acquire('a', 1.minute) do
        results << 'second'
      end
    
    end
    

    a.join; b.join
    
    assert_equal ['first', 'second'], results
  end
end