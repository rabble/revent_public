require File.dirname(__FILE__) + '/../spec_helper'

describe EventSweeper do
  include CacheSpecHelpers
  describe "when an event is created" do
    before do
      ActionController::Base.page_cache_directory = File.join(RAILS_ROOT,'tmp','cache')
      Site.stub!(:current).and_return new_site
      # so sync to DIA does not happen
      Site.stub!(:current_config_path).and_return('tmp')
      @calendar = new_calendar
      @permalink = @calendar.permalink
    end

    it "should expire the calendar show page" do
      cache_url(url = "#{@calendar.permalink}/calendars/show.html")
      lambda {create_event}.should expire_page(url)
    end

    it "should expire the index page" do
      cache_url(url = 'index.html')
      lambda {create_event}.should expire_page(url)
    end

    it "should expire the permalink" do
      cache_url(url = "#{@calendar.permalink}.html")
      lambda {create_event}.should expire_page(url)
    end

    it "should expire total.js" do
      cache_url(url = "events/total.js")
      lambda {create_event}.should expire_page(url)
    end

    it "should expire total.html" do
      cache_url(url = "events/total.html")
      lambda {create_event}.should expire_page(url)
    end
  end
end
