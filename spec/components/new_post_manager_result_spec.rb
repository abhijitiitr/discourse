require 'spec_helper'
require 'new_post_manager/result'

describe NewPostManager::Result do

  it "fails by default" do
    result = NewPostManager::Result.new(:eviltrout)
    expect(result.failed?).to eq(true)
    expect(result.success?).to eq(false)
  end

end
