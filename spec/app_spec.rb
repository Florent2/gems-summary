require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'MyApp' do

  def app
    Sinatra::Application
  end

  describe "GET /" do
    it "is successful" do
      get "/"
      last_response.should be_ok
    end

    it "displays an explanation about Gems Summary" do
      get "/"
      last_response.body.should include("showing each day all the gems newly released and updated")
    end
  end

  describe "GET /2011-04-13" do

    it "does not display a gem created another day" do
      old_new_gem = GemRecord.create :name => "old new gem", :project_uri => "http://rubygems.org/gems/old-new-gem"
      old_new_gem.versions.create :number => "0.1", :created_on => Date.civil(2010, 1, 1), :first_version => true
      get "/2011-04-13"
      last_response.body.should_not include("old new gem")
    end

    it "does not display a gem updated another day" do
      old_updated_gem = GemRecord.create :name => "old updated gem", :project_uri => "http://rubygems.org/gems/old-updated-gem"
      old_updated_gem.versions.create :number => "0.2", :created_on => Date.civil(2010, 10, 1), :first_version => false
      get "/2011-04-13"
      last_response.body.should_not include("old updated gem")
    end

    it "displays a gem released this day" do
      new_gem = GemRecord.create :name => "new gem", :project_uri => "http://rubygems.org/gems/new-gem"
      new_gem.versions.create :number => "0.1", :created_on => Date.civil(2011, 4, 13), :first_version => true
      get "/2011-04-13"
      last_response.body.should include("new gem")
    end

    it "displays a gem updated this day" do
      updated_gem = GemRecord.create :name => "updated gem", :project_uri => "http://rubygems.org/gems/updated-gem"
      updated_gem.versions.create :number => "0.1", :created_on => Date.civil(2011, 4, 13), :first_version => false
      get "/2011-04-13"
      last_response.body.should include("updated gem")
    end

    it "warns when there is no available data for this day" do
      oldest_gem = GemRecord.create :name => "oldest", :project_uri => "http://rubygems.org/gems/oldest"
      oldest_gem.versions.create :number => "0.1", :created_on => Date.civil(2010, 1, 1)
      get "/2009-1-1"
      last_response.body.should include("Gems Summary has only data from the 2010-01-01")
    end

  end

  describe "/POST version" do

    context "when posted JSON data are incomplete" do
      it "raises an exception when there is no JSON data" do
        expect { post "/version" }.to raise_error(JSON::ParserError)
      end

      it "raises an exception if the GemRecord could not be created from the JSON data" do
        expect { post "/version", {:name => "some gem"}.to_json }.to raise_error(DataMapper::SaveFailureError)
      end
    end

    describe "Gem record creation or update" do
      it "creates a new gem record if there is no previous gem record with the same name" do
        expect {
          post "/version", {:name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :version => "0.1"}.to_json
        }.to change(GemRecord, :count).by(1)
      end

      it "does not create a new gem record if there is already a gem record with the same name" do
        GemRecord.create :name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem"
        expect {
          post "/version", {:name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :version => "0.1"}.to_json
        }.to change(GemRecord, :count).by(0)
      end

      it "updates the gem attributes if they have changed" do
        gem = GemRecord.create :name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :info => "some info"
        post "/version", {:name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :version => "0.1", :info => "newer info"}.to_json
        gem.reload.info.should == "newer info"
      end
    end

    describe "Version creation or update" do
      context "when it's the first version of the gem for this day" do
        it "when it's the first version of the gem, it creates a version record marked as first version" do
          post "/version", {:name => "new gem", :project_uri => "http://rubygems.org/gems/new-gem", :version => "0.1"}.to_json
          Version.last.attributes.should include(
            :gem_record_id => GemRecord.first(:name => "new gem").id,
            :name          => "new gem",
            :number        => "0.1",
            :created_on    => Date.today,
            :first_version => true
          )
        end

        it "when it's not the first version of the gem, it creates a version record not marked as first version" do
          post "/version", {:name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :version => "0.1"}.to_json
          Version.last.attributes.should include(
            :gem_record_id => GemRecord.first(:name => "some gem").id,
            :name          => "some gem",
            :number        => "0.1",
            :created_on    => Date.today,
            :first_version => false
          )
        end
      end

      it "when it's not the first version of the gem for this day, it updates the existing version of this day with the new version" do
        post "/version", {:name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :version => "0.1"}.to_json
        post "/version", {:name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem", :version => "0.2"}.to_json
        Version.count.should == 1
        Version.last.attributes.should include(:number => "0.2")
      end
    end
  end

end
