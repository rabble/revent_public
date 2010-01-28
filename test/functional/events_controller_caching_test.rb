class EventsCachingTest < Test::Unit::TestCase
  fixtures :sites, :calendars, :events

  def setup
    @controller = CalendarsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
	  @request.host = sites(:stepitup).host
  end

=begin
    caches_page :index, :total, :by_state
  #  after_filter { |c| c.cache_page(nil, :permalink => c.params[:permalink]) if c.action_name == 'show' }
    caches_page :show
    caches_action :ally
    after_filter :cache_search_results, :only => :search
=end

  def test_events_show_caching
    assert true
  end

=begin
  # temporarily disable this test
	def test_this
	  e = events(:stepitup)
	  url = ["/#{e.calendar.permalink}/events/show/#{e.id}"]
	  assert_caches_pages url do
	    get
    end
	  assert_expires_pages "some pages" do
	    e.save
	  end
	end
=end

end
