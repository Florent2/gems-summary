require "date"

require "logger"
LOG_DIR = File.join File.expand_path(File.dirname __FILE__), "tmp"
Dir.mkdir(LOG_DIR) unless Dir.exists?(LOG_DIR)
LOGGER_FILE = File.join LOG_DIR, "app.log"
FileUtils.touch(LOGGER_FILE) unless File.exists?(LOGGER_FILE)
logger = Logger.new LOGGER_FILE

DataMapper.setup(:default, ENV["DATABASE_URL"] || "postgres://localhost/gems-summary-development")
DataMapper::Property::String.length(255)
DataMapper::Model.raise_on_save_failure = true

$LOAD_PATH.unshift(File.join File.dirname(__FILE__), "models")
Dir.glob(File.join File.dirname(__FILE__), "models", "*.rb") { |model| require File.basename(model, '.*') }

DataMapper.finalize
DataMapper.auto_upgrade!

configure { set :views, File.join(File.dirname(__FILE__), "views") }

if production? && ENV["HOPTOAD_API_KEY"]
  HoptoadNotifier.configure { |config| config.api_key = ENV["HOPTOAD_API_KEY"] }
  use HoptoadNotifier::Rack
  enable :raise_errors
end

get "/" do
  @feed_url                         = if production? then "http://feeds.feedburner.com/GemsSummary" else "/daily.rss" end
  @yesterday_new_gems_versions      = Version.new_on Date.today.prev_day
  @yesterday_updated_gems_versions  = Version.updated_on Date.today.prev_day
  haml :index
end

get %r{/(\d\d\d\d)\-(\d\d?)\-(\d\d?)} do |year, month, day|
  @date                   = Date.civil year.to_i, month.to_i, day.to_i
  return "Gems Summary has only data from the #{Version.first.created_on}" if @date < Version.first.created_on

  @new_gems_versions      = Version.new_on @date
  @updated_gems_versions  = Version.updated_on @date

  haml :day
end

get "/daily.rss" do
  @base_url = "#{request.scheme}://#{request.host}#{":" + request.port.to_s if request.port != 80}/"

  @versions_by_date = Hash.new { |hash, key| hash[key] = {} }
  dates = ((Date.today.prev_day - 6)..Date.today.prev_day).to_a.reverse
  dates.each do |date|
    @versions_by_date[date][:new]     = Version.new_on date
    @versions_by_date[date][:updated] = Version.updated_on date
  end

  builder :day
end

post "/#{ENV['ENDPOINT_PATH'] || 'version'}" do
  body = request.body.read
  logger.info "received JSON body = #{body.inspect}" # logged in dedicated file, as only x hundreds lines are available in Heroku logs
  hash = JSON.parse body

  gem = GemRecord.create_or_update({
    :name         => hash["name"],
    :info         => hash["info"],
    :homepage_uri => hash["homepage_uri"],
    :project_uri  => hash["project_uri"],
  })

  Version.create_or_update({
    :gem_record => gem,
    :number     => hash["version"],
    :created_on => Date.today
  })

  puts "Version #{hash["version"]} created for #{gem.name}" unless test?
end

helpers do

  # TODO : make spec
  def display_version(version)
    result = "<a href='#{version.gem_record.project_uri}'>#{CGI::escapeHTML version.gem_record.name}</a>"
    result += " #{version.number}" unless version.first_version
    result += " [<a href='#{version.gem_record.homepage_uri}'>#{version.gem_record.homepage_uri_host}</a>]" if version.gem_record.homepage_uri_host && version.gem_record.homepage_uri != version.gem_record.project_uri
    result + "<br />" + CGI::escapeHTML(version.gem_record.info || "")
  end

end
