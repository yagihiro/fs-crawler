require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Crawler::Filesystem" do

  before(:all) do
    @options = {
      :port             => 30001,
      :host             => "0.0.0.0",
      :distination_port => 30002,
      :distination_host => "0.0.0.0",
      :config           => "./.fs-crawler.yml"
    }
  end
  
  it "construction" do
    Crawler::Filesystem.new(@options).should_not be_nil
  end
  
end
