require File.join(File.dirname(__FILE__), 'spec_helper')

describe Version do

	let(:gem)     { GemRecord.create :name => "new gem", :project_uri => "http://rubygems.org/gems/new-gem" }
	let(:version) { gem.versions.create :number => "0.1", :first_version => true }

  it "#number is required" do
    Version.should require(:number)
  end

  describe "#name" do

    it "is required" do
      Version.should require(:name)
    end

    it "is automatically populated from its gem record name" do
      version.name.should == "new gem"
    end

    it "stays nil if not set and gem record not set" do
      version = Version.new
      version.valid?
      version.name = nil
    end

  end

  describe "#created_on" do

    it "is set by default to today" do
      version.created_on.should == Date.today
    end

    it "can be set manually" do
      version.update :created_on => Date.today.prev_day
      version.created_on.should == Date.today.prev_day
    end

  end

	describe ".create_or_update(attributes)" do

		it "when there is already a version for the same gem record and for the same day, it updates it" do
			version # seems necessary to have the version record in the db...
			Version.create_or_update :gem_record => gem, :number => "0.2", :created_on => Date.today
      version.reload.attributes.should include(:number => "0.2", :first_version => true)
		end
		
		it "when there is no version for the same gem record on the same day, it creates a new version and returns it" do
			version # seems necessary to have the version record in the db...
			new_version = Version.create_or_update :gem_record => gem, :number => "0.2", :created_on => Date.today.next_day
      new_version.attributes.should include(:number => "0.2", :first_version => false)
			version.reload.number.should == "0.1"
		end

	end	

	it ".new_on(date) returns only the versions of new gems for the given date" do
	  other_gem = GemRecord.create :name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem"
    other_gem.versions.create :number => "0.1", :created_on => Date.today.prev_day, :first_version => true  # new version on previous day
    other_gem.versions.create :number => "0.2", :created_on => Date.today                                   # updated version on same day
	  gem.versions.create :number => "0.2", :created_on => Date.today.next_day                                # updated version on other day
    Version.new_on(Date.today).should == [version]
	end

  it ".updated_on(date) returns only the versions of gems updated during the given date" do
    other_gem = GemRecord.create :name => "some gem", :project_uri => "http://rubygems.org/gems/some-gem"
    other_gem.versions.create :number => "0.1", :created_on => Date.today.prev_day, :first_version => true  # new version on previous day
    updated_gem = other_gem.versions.create :number => "0.2", :created_on => Date.today                     # updated version on same day
	  gem.versions.create :number => "0.2", :created_on => Date.today.next_day                                # updated version on other day
    Version.updated_on(Date.today).should == [updated_gem]
  end

end
