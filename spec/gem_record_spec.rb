require File.join(File.dirname(__FILE__), 'spec_helper')

describe GemRecord do

	let(:gem) { GemRecord.create :name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem" }

	describe "#name" do

		it "is required" do
      GemRecord.should require(:name)
		end

		it "is unique" do
			new_gem = GemRecord.new gem.attributes.merge({:id => nil})
			new_gem.should_not be_valid
			new_gem.errors[:name].should == ["Name is already taken"]
		end

	end

	it "#project_uri is required" do
    GemRecord.should require(:project_uri)
	end

	describe "#homepage_uri_host" do

		it "returns the host if homepage_uri is parsable" do
			gem.homepage_uri = "http://github.com/user/project"
			gem.homepage_uri_host.should == "github.com"
		end
		
		it "returns nil is homepage_uri is nil" do
			gem.homepage_uri_host.should be_nil
		end
		
		it "returns nil if homepage_uri is an empty string" do
			gem.homepage_uri = ""
			gem.homepage_uri_host.should be_nil
		end
		
		it "returns nil if homepage_uri is not a parsable URI" do
			gem.homepage_uri = "http://github.com/\#{github_username}/\#{project_name}"
			gem.homepage_uri_host.should be_nil
		end

	end

	describe "#is_new?" do

		it "returns false when there is already at least one version associated to the gem in the Gems Summary db" do
			gem.versions.create :number => "0.2"
      gem.is_new?.should be_false
		end
		
		context "when there is no version associated to the gem in the Gems Summary db" do
		
			it "returns false if the total numbers of download of the gem is different than the number of download of the last version of the gem" do
			  stub_request(:get, "http://rubygems.org/api/v1/gems/some%20gem.json").to_return(:body => {:version_downloads => 20, :downloads => 10}.to_json)
				gem.is_new?.should be_false	
			end
		
			it "returns true if the total numbers of download of the gem is equal to the number of download of the last version of the gem" do
			  stub_request(:get, "http://rubygems.org/api/v1/gems/some%20gem.json").to_return(:body => {:version_downloads => 20, :downloads => 20}.to_json)
				gem.is_new?.should be_true
			end

		end
	end

	describe ".create_or_update(attributes)" do

		it "when there is already a gem record with this name, it updates it and returns it" do
			GemRecord.create_or_update({:name => gem.name, :project_uri => gem.project_uri, :info => "some info"}).attributes.should include(:info => "some info", :id => gem.id)
		end
		
		it "when there is no gem record with this name, it creates a new gem record and returns it" do
			GemRecord.count.should be_zero
			GemRecord.create_or_update({:name => "other gem", :project_uri => "http://rubygems.org/gems/other-gem"}).should == GemRecord.first(:name => "other gem")
		end
	
	end
end
