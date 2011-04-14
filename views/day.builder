xml.instruct! :xml, :version => '1.0'
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Gems Summary"
    xml.description "List of all the gems newly released and updated on RubyGems"
    xml.link @base_url

    @versions_by_date.each_pair do |date, versions|
      page_url = @base_url + date.to_s
      xml.item do
        xml.title "On #{date}"
        xml.link page_url
        xml.description haml(:_day, {}, :new_gems_versions => versions[:new], :updated_gems_versions => versions[:updated], :page_url_for_rss_readers => page_url)
        xml.pubDate date.rfc822
        xml.guid page_url
      end
    end
  end
end
