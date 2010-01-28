require File.dirname(__FILE__) + '/../test_helper'

require 'mocha'
#require 'DIA_API_Simple'
require 'democracyinaction'

class CachingTest < ActionController::IntegrationTest
  fixtures :events, :users, :sites, :calendars, :reports

  def setup
    FileUtils.rm_rf   ActionController::Base.page_cache_directory rescue nil
    FileUtils.mkdir_p ActionController::Base.page_cache_directory
    @mock_dia_api = stub(:get => [
                      {'event_KEY' => '1111', 'Event_Name' => 'expire test new event', 'Address' => 'locaction', 'Description' => 'description', 'City' => 'city', 'State' => 'CA', 'Zip' => '94110', 'Start' => 1.hour.from_now, 'End' => 2.hours.from_now, 'Directions' => 'directions'},
                      {'event_KEY' => '1000', 'Event_Name' => 'expire test updated event', 'Address' => 'locaction', 'Description' => 'description', 'City' => 'city', 'State' => 'CA', 'Zip' => '94110', 'Start' => 1.hour.from_now, 'End' => 2.hours.from_now, 'Directions' => 'directions'}
    ])
    DIA_API_Simple.stubs(:new).returns(@mock_dia_api)
    disable_geocode
  end

  def test_should_expire_only_list_pages_and_fragments_on_create
    host!(sites(:stepitup).host)
    e = events(:stepitup)
    c = e.calendar
    populate_events_page_cache(c)
    get "/#{c.permalink}/events/show/#{e.id}"
    assert_caches_pages "/#{c.permalink}.html",
          "/#{c.permalink}/events/show/#{e.id}", 
          "/#{c.permalink}/events/show/6", 
          "/#{c.permalink}/events/flashmap.xml", 
          "/#{c.permalink}/events/search/state/AZ", 
          "#{c.permalink}/events/search/state/CA"
    assert_expires_pages "/#{c.permalink}.html", "/#{c.permalink}/events/flashmap.xml", "/#{c.permalink}/events/search/state/CA" do
      post "/events/create", :user => {:email => 'expire_cache@test.com'}, :event => {:calendar_id => c.id, :name => 'Expire Cache Test Event', :start => 3.days.from_now, :end => 3.days.from_now + 1.hour, :host_id => 3, :state => 'CA', :city => 'San Francisco', :description => 'description', :location => '1942 15th St.', :postal_code => '94114'}
    end
    assert_caches_pages "/#{c.permalink}/events/show/6", "/#{c.permalink}/events/search/state/AZ"
  end

  def test_should_expire_only_show_and_state_on_update
    e = events(:stepitup)
    c = e.calendar
    host! c.site.host
    DemocracyInActionSupporter.any_instance.stubs(:events).returns([e])
    s = DemocracyInActionSupporter.new(:Email => 'test@test.com', :Password => Digest::MD5.hexdigest('password'))
    DemocracyInActionSupporter.stubs(:find).returns(s)
    populate_events_page_cache(c)
    get "/#{c.permalink}/events/show/#{e.id}"
    assert_caches_pages "/#{c.permalink}.html",
                        "/#{c.permalink}/events/flashmap.xml", 
                        "/#{c.permalink}/events/show/#{e.id}", 
                        "/#{c.permalink}/events/show/6",
                        "/#{c.permalink}/events/search/state/AZ", 
                        "/#{c.permalink}/events/search/state/CA" do
    end
    post "/login", :email => 'test@test.com', :password => 'password'
    assert_equal session[:user], s
    assert session[:user].events.include?(e)
    assert_expires_pages "/#{c.permalink}/events/search/state/CA", "/#{c.permalink}/events/show/#{e.id}" do
      post "/account/events/update/#{e.id}", :event => {:name => 'changed'}
    end
    assert_caches_pages "/#{c.permalink}/events/show/2", 
      "/#{c.permalink}/events/search/state/AZ", 
      "/#{c.permalink}.html", 
      "/#{c.permalink}/events/flashmap.xml"
  end

  def test_should_expire_report_caches
    host! sites(:stepitup).host
    report = reports(:first)
    DemocracyInActionSupporter.any_instance.stubs(:events).returns([report.event])
    s = DemocracyInActionSupporter.new(:Email => 'test@test.com', :Password => Digest::MD5.hexdigest('password'))
    DemocracyInActionSupporter.stubs(:find).returns(s)
    populate_reports_page_cache

    host! 'events.stepitup2007.org'
    post "/login", :email => 'test@test.com', :password => 'password'

    assert_caches_pages "/reports.html", "/reports/list.html", "/reports/page/2.html", "/reports/1.html", "/reports/flashmap.xml"

    assert_expires_pages "/reports/list.html", "/reports/1.html", "/reports/flashmap.xml", "/reports/page/2.html" do
      post "/account/reports/update/#{report.id}", :report => {:text => 'changed'}
    end
    assert_caches_pages "/reports.html"

    populate_reports_page_cache

    assert_expires_pages "/reports/list.html", "/reports/flashmap.xml", "/reports/page/2.html" do
      post "/reports/create", :report => {:event_id => 2, :text => 'new report', :reporter_name => 'jon', :reporter_email => 'jw@stepitup.org'}, :press_links => [{:url => '', :text => ''}], :attachments => [{:uploaded_data => ''}]
    end
    assert_caches_pages "/reports.html", "/reports/1.html"
  end

  def populate_events_page_cache(calendar)
    get "/#{calendar.permalink}"
    get "/#{calendar.permalink}/events/flashmap.xml" #have to fake the flash request
    get "/#{calendar.permalink}/events/search/state/AZ"
    get "/#{calendar.permalink}/events/search/state/CA"
    get "/#{calendar.permalink}/events/show/6"
  end
  def populate_reports_page_cache
    get "/reports"
    get "/reports/list"
    get "/reports/page/2"
    get "/reports/1"
    get "/reports/flashmap.xml"
  end
end
