require "rubygems"
require "bundler"
Bundler.require :default, :test
require File.join(File.dirname(__FILE__), '..', 'app.rb')

require 'rack/test'
include Rack::Test::Methods

require 'rspec'

require "webmock/rspec"
WebMock.disable_net_connect!

set :environment, :test

DataMapper.setup :default, "sqlite::memory:"

RSpec::Matchers.define :require do |attribute|
  match do |model|
    instance = model.new
    instance.valid?
    instance.errors[attribute].should == ["#{attribute.to_s.capitalize} must not be blank"]
  end
end

Rspec.configure do |config|

  config.before(:each) do
    DataMapper.auto_migrate!
    stub_request(:get, "http://rubygems.org/api/v1/gems/some%20gem.json").to_return(:body => {:version_downloads => 20, :downloads => 10}.to_json)
    stub_request(:get, "http://rubygems.org/api/v1/gems/new%20gem.json").to_return(:body => {:version_downloads => 10, :downloads => 10}.to_json)
  end

  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

