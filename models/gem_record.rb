# ideally should be name Gem, but that's not possible
# a better name would be RubyGem maybe
class GemRecord
	include DataMapper::Resource
  property :id,           Serial
  property :name,         String, :required => true, :unique => true
  property :project_uri,  String, :required => true
  property :homepage_uri, String
  property :info,         Text

  has n, :versions

  def homepage_uri_host
    URI.parse(homepage_uri).host rescue nil
  end

  def is_new?
    return false if !versions.empty?
    gem_data = JSON.parse Curl::Easy.perform("http://rubygems.org/api/v1/gems/#{name}.json").body_str
    gem_data["version_downloads"] == gem_data["downloads"]
  end

	def self.create_or_update(attributes)
    gem = first :name => attributes[:name]
    if gem
      gem.update attributes
      gem
    else
      create attributes
    end
  end
end


