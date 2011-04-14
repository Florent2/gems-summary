class Version
  include DataMapper::Resource
  property :id,             Serial
  property :number,         String,   :required => true
  property :created_on,     Date,     :required => true
  property :first_version,  Boolean,  :required => true, :default => false
  # duplicated from GemRecord to be able to sort by the gem name, because DM does not permit to sort result by another association http://groups.google.com/group/datamapper/browse_thread/thread/42859f378034aa4
  property :name,           String,   :required => true

  belongs_to :gem_record

  before :valid? do
    self.name       = gem_record.name unless gem_record.nil?
    self.created_on = Date.today if self.created_on.nil?
  end

  # if a version already exists for this gem on the same day, updates its version number, else creates a new version
  def self.create_or_update(attributes)
    existing_version = Version.first :created_on => attributes[:created_on], :gem_record => attributes[:gem_record]
    if existing_version
      existing_version.update attributes
    else
      attributes[:first_version] = attributes[:gem_record].is_new?
      create attributes
    end
  end

  def self.new_on(date)
    all :created_on => date, :order => :name, :first_version => true
  end

  def self.updated_on(date)
    all :created_on => date, :order => :name, :first_version => false
  end

 end
