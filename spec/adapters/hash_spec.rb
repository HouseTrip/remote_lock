require 'spec_helper'

describe Hash do
  it_behaves_like 'a remote lock adapter', {}
end
