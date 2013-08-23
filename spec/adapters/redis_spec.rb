require 'spec_helper'

module RemoteLock::Adapters
  describe Redis do
    it_behaves_like 'a remote lock adapter', redis

    context "Redis scope" do
      let(:adapter) { Redis.new(redis) }
      let(:uid)      { '1234' }
      let(:test_key) { "test_key" }

      before do
        adapter.stub(:uid).and_return(uid)
      end

      describe "#store" do
        it "should store the lock in memcached" do
          redis.get("lock/#{test_key}").should be_nil
          adapter.store(test_key, 100)
          redis.get("lock/#{test_key}").should eq uid
        end

        context "expiry" do
          it "should expire the key after the time is over" do
            adapter.store(test_key, 1)
            sleep 1.1
            redis.exists("lock/#{test_key}").should be_false
          end

          it "should expire the key after the time is over" do
            adapter.store(test_key, 10)
            sleep 0.5
            redis.exists("lock/#{test_key}").should be_true
          end
        end
      end

      describe "#has_key?" do
        it "should return true if the key exists in memcache with uid value" do
          redis.setnx("lock/#{test_key}", uid)
          adapter.has_key?(test_key).should be_true
        end

        it "should return false if the key doesn't exist in memcache or is a different uid" do
          redis.setnx("lock/#{test_key}", "notvalid")
          adapter.has_key?(test_key).should be_false
          redis.del("lock/#{test_key}")
          adapter.has_key?(test_key).should be_false
        end
      end

      describe "#delete" do
        it "should remove the key from memcached" do
          redis.setnx("lock/#{test_key}", uid)
          adapter.delete(test_key)
          redis.get("lock/#{test_key}").should be_nil
        end
      end
    end
  end
end
