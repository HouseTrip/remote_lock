require 'spec_helper'

module RemoteLock::Adapters
  describe Memcached do
    it_behaves_like 'a remote lock adapter', memcache

    context "Memcache scope" do
      let(:adapter)  { Memcached.new(memcache) }
      let(:uid)      { '1234' }
      let(:test_key) { "test_key" }

      before do
        adapter.stub(:uid).and_return(uid)
      end

      describe "#store" do
        it "should store the lock in memcached" do
          memcache.get(test_key).should be_nil
          adapter.store(test_key, 100)
          memcache.get(test_key).should eq uid
        end
      end

      describe "#has_key?" do
        it "should return true if the key exists in memcache with uid value" do
          memcache.add(test_key, uid)
          adapter.has_key?(test_key).should be_true
        end

        it "should return false if the key doesn't exist in memcache or is a different uid" do
          memcache.add(test_key, "notvalid")
          adapter.has_key?(test_key).should be_false
          memcache.delete(test_key)
          adapter.has_key?(test_key).should be_false
        end
      end

      describe "#delete" do
        it "should remove the key from memcached" do
          memcache.add(test_key, uid)
          adapter.delete(test_key)
          memcache.get(test_key).should be_nil
        end
      end
    end
  end
end
