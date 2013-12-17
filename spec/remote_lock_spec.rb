require 'spec_helper'

describe RemoteLock do

  adapters = {
    :memcached => RemoteLock::Adapters::Memcached.new(memcache),
    :redis => RemoteLock::Adapters::Redis.new(redis)
  }

  adapters.each_pair do |name, adapter|
    context "Using adapter: #{name}" do
      before do
        Kernel.stub(:sleep)
      end

      let(:lock) { RemoteLock.new(adapter) }

      describe "#synchronize" do

        it "yields the block" do
          expect { |call|
            lock.synchronize('lock_key', &call)
          }.to yield_control
        end

        it "acquires the specified lock before the block is run" do
          adapter.has_key?("lock_key").should be_false
          lock.synchronize('lock_key') do
            adapter.has_key?("lock|lock_key").should be_true
          end
        end

        it "releases the lock after the block is run" do
          adapter.has_key?("lock_key").should be_false
          expect { |call| lock.synchronize('lock_key', &call) }.to yield_control
          adapter.has_key?("lock|lock_key").should be_false
        end

        it "releases the lock even if the block raises" do
          adapter.has_key?("lock|lock_key").should be_false
          lock.synchronize('lock_key') { raise } rescue nil
          adapter.has_key?("lock|lock_key").should be_false
        end

        specify "does not block on recursive lock acquisition" do
          lock.synchronize('lock_key') do
            lambda {
              expect{ |call| lock.synchronize('lock_key', &call) }.to yield_control
            }.should_not raise_error
          end
        end

        it "permits recursive calls from the same thread" do
          lock.acquire_lock('lock_key')
          lambda {
            expect { |call| lock.synchronize('lock_key', &call) }.to yield_control
          }.should_not raise_error
        end

        it "prevents calls from different threads" do
          lock.acquire_lock('lock_key')
          another_thread do
            lambda {
              expect { |call| lock.synchronize('lock_key', &call) }.to_not yield_control
            }.should raise_error(RemoteLock::Error)
          end
        end
      end

      describe '#acquire_lock' do
        specify "creates a lock at a given cache key" do
          adapter.has_key?("lock|lock_key").should be_false
          lock.acquire_lock("lock_key")
          adapter.has_key?("lock|lock_key").should be_true
        end

        specify "retries as long as the expiry times is not reached" do
          lock.acquire_lock('lock_key')
          another_process do
            adapter.should_receive(:store).exactly(11).times.and_return(false)
            lambda {
              lock.acquire_lock('lock_key', :expiry => 10)
            }.should raise_error(RemoteLock::Error, "Couldn't acquire lock for: lock_key - Retried for 10.01 seconds in 11 attempt(s)")
          end
        end

        specify "correctly sets timeout on entries" do
          adapter.should_receive(:store).with('lock|lock_key', 42).and_return true
          lock.acquire_lock('lock_key', :expiry => 42)
        end

        specify "prevents two processes from acquiring the same lock at the same time" do
          lock.acquire_lock('lock_key')
          another_process do
            lambda { lock.acquire_lock('lock_key') }.should raise_error(RemoteLock::Error)
          end
        end

        specify "prevents two threads from acquiring the same lock at the same time" do
          lock.acquire_lock('lock_key')
          another_thread do
            lambda { lock.acquire_lock('lock_key') }.should raise_error(RemoteLock::Error)
          end
        end

        specify "prevents a given thread from acquiring the same lock twice" do
          lock.acquire_lock('lock_key')
          lambda { lock.acquire_lock('lock_key') }.should raise_error(RemoteLock::Error)
        end
      end

      describe '#release_lock' do
        specify "deletes the lock for a given cache key" do
          adapter.has_key?("lock|lock_key").should be_false
          lock.acquire_lock("lock_key")
          adapter.has_key?("lock|lock_key").should be_true
          lock.release_lock("lock_key")
          adapter.has_key?("lock|lock_key").should be_false
        end
      end

      context "lock prefixing" do
        it "should prefix the key name when a prefix is set" do
          lock = RemoteLock.new(adapter, "staging_server")
          lock.acquire_lock("lock_key")
          adapter.has_key?("staging_server|lock|lock_key").should be_true
        end
      end
    end
  end

  #  helpers

  def another_process
    current_pid = Process.pid
    Process.stub :pid => (current_pid + 1)
    redis.client.reconnect
    yield
    Process.unstub :pid
    redis.client.reconnect
  end

  def another_thread
    old_tid = Thread.current[:thread_uid]
    Thread.current[:thread_uid] = nil
    yield
    Thread.current[:thread_uid] = old_tid
  end

end
