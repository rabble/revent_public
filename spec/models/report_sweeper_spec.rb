require File.dirname(__FILE__) + '/../spec_helper'

describe ReportSweeper do
  include CacheSpecHelpers
  include CacheCustomMatchers
  before do
    test_cache_dir = File.join(RAILS_ROOT, 'tmp', 'cache', 'local_revent.org')
    File.exists?(test_cache_dir) ? FileUtils.rm_rf(test_cache_dir) : FileUtils.mkdir_p(test_cache_dir)
    ActionController::Base.page_cache_directory = test_cache_dir
    ActionController::Base.perform_caching = true
  end
  describe "on create" do
    before do 
      Site.current = new_site(:id => 1)
      @event = create_event
      permalink = @event.calendar.permalink
      @urls = [ 
        "/reports/list.html",
        "/#{permalink}/reports/list.html",
        "/reports/#{@event.id}.html",
        "/#{permalink}/reports/#{@event.id}.html",
        "/reports/flashmap.xml",
        "/#{permalink}/reports/flashmap.xml",
        "/events/show/#{@event.id}.html",
        "/#{permalink}/events/show/#{@event.id}.html",
        "/reports/search/state/#{@event.state}.html",
        "/#{permalink}/reports/search/state/#{@event.state}.html",
        "/reports/page/page1.html",
        "/#{permalink}/reports/page/page1.html",
        "/reports/press.html",
        "/#{permalink}/reports/press.html",
        "/reports/video.html",
        "/#{permalink}/reports/video.html",
        #"/reports/lightbox/123.html",
        #"/#{permalink}/reports/lightbox/123.html",
      ]
      cache_urls(*@urls)
    end
    it "should delete the reports show page" do
      lambda { create_report(:event => @event) }.should expire_pages(@urls)
    end
  end
  #describe "on save" # do; end
  #describe "on destroy" #do; end
end
