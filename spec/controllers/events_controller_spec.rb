require File.dirname(__FILE__) + '/../spec_helper.rb'

describe EventsController do
  before do
    @site       = new_site
    @site.calendars << (@calendar = new_calendar(:site => @site))
    @calendar.id = 1
    request.host = @site.host
    Site.current = @site
    controller.stub!(:clean)
  end

  it "should set site from host" do
    get :index
    @controller.site.host.should == @site.host
  end

  it "should redirect on index if no query" do
    get :index
    response.should be_redirect
  end

  describe "show" do
    before do
      @event = new_event
      @calendar.stub!(:events).and_return(stub('events', :find => @event))
      get :show, :id => 111
    end
    it "should be success" do
      response.should be_success
    end
    it "should use show template" do
      response.should render_template('show')
    end
    it "should assign event" do
      assigns[:event].should == @event
    end
  end
  describe "new" do
    before do
      get :new, :calendar_id => 1
    end
    it "should be success" do
      response.should be_success
    end
    it "should use show template" do
      response.should render_template('new')
    end
    it "should assign event" do
      assigns[:event].should_not be_nil
    end
  end
  describe "create" do
    describe "with new user" do
      before do
        @user = new_user
        @user.stub!(:save!)
        @user.stub!(:valid?).and_return(true)
        controller.stub!(:find_or_build_related_user).and_return @user
        @event = new_event
        @event.id = 1
        @event.stub!(:save!)
        @event.stub!(:valid?).and_return(true)
        @calendar.stub!(:events).and_return(stub('event', :build => @event))
      end
      def act!(user=nil)
        post :create, :permalink => @calendar.permalink
      end
      it "should redirect" do
        act!
        response.should be_redirect
      end
      it "should redirect to show" do
        act!
        response.should redirect_to(:host => @site.host, :permalink => @calendar.permalink, :action => 'show', :id => 1)
      end
    end
  end

  it "shows recently added" do
    get 'recently_added', :format => 'xml'
    response.should be_success
  end
  it "shows recently upcoming" do
    get 'upcoming', :format => 'xml'
    response.should be_success
  end
end
