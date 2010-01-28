require 'httpclient'

class EventsController < ApplicationController
  include DaysOfAction::Geo
  helper :maps #XXX
  include MapsHelper #XXX
  before_filter :disable_create, :only => [:new, :create, :rsvp]
  def disable_create
    redirect_to(home_url) && return if @calendar.archived?
    if params[:id]
      @event = @calendar.events.find(params[:id]) 
      redirect_to home_url if @event.past?
    else
      redirect_to home_url if @calendar.past?
    end
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [:create, :rsvp], :redirect_to => {:action => 'index'}

  caches_page_unless_flash :total, :by_state, :show, :simple, :international
  caches_action :index
  def action_fragment_key(options)
    request.host + Digest::SHA1.hexdigest(params.to_a.sort.to_s) + "version#{all_events_cache_version}"
  end
  def all_events_cache_version
    Cache.get("site_#{Site.current.id}_all_events_version") { rand(10000) }
  end

  cache_sweeper :event_sweeper, :only => :create
  after_filter :cache_search_results, :only => :search
  def cache_search_results
    if params[:state]
      if params[:permalink]
        # cache_page accepts string for second argument in rails v2.0
        # replace url_for hash with state_search_url  once upgrade to 2.0
        cache_page nil, :permalink => params[:permalink], :controller => :events, :action => :search, :state => params[:state] 
      else
        cache_page 
      end
    end
  end

  def cache_version
    Cache.get(cache_version_key) { rand(10000) }
  end

  def cache_version_key
    "site_#{Site.current.id}_#{self.class.to_s.underscore}_#{action_name}_cache_version"
  end

  def tagged
    @tag = Tag.find_or_initialize_by_name(params[:id])
    @events = @tag.events(:conditions => ["calendar_id = ?", @calendar.id])
  end
  
  def category
    @category_options = @calendar.categories.collect{|c| [c.name, c.id]}.unshift(['All Events', 'all'])
    if params[:id] and not params[:id] == 'all'
      @category = @calendar.categories.find(params[:id])  
      @events = @calendar.events.searchable.paginate_all_by_category_id(@category.id, :order => 'created_at DESC', :page => params[:page])
    else
      require 'ostruct'
      @category = OpenStruct.new(:id => 'all', :name => 'All Events')
      @events = @calendar.events.searchable.paginate(:all, :order => 'created_at DESC', :page => params[:page])
    end
  end

  def flashmap
    @events = @calendar.events.searchable.mappable.find :all
    respond_to do |format|
      format.xml { render :layout => false }
    end
    cache_page nil, :permalink => params[:permalink]
  end
  
  def recently_updated
    respond_to do |format|
      format.html do 
        @events = @calendar.events.searchable.paginate(:all, :order => 'updated_at DESC', :page => params[:page])
      end
      format.xml do 
        @events = @calendar.events.searchable.find(:all, :order => 'updated_at DESC', :limit => 4)
        render :action => 'recently_updated.rxml', :layout => false
      end
    end
  end

  def recently_added 
    respond_to do |format|
      format.html do 
        @events = @calendar.events.searchable.paginate(:all, :order => 'created_at DESC', :page => params[:page])
      end
      format.xml do 
        @events = @calendar.events.searchable.find(:all, :order => 'created_at DESC', :limit => 4)
        render :action => 'recently_added.rxml', :layout => false
      end
    end
  end

  def upcoming
    respond_to do |format|
      format.html do 
        @events = @calendar.events.searchable.upcoming.paginate(:page => params[:page])
      end
      format.xml do 
        @events = @calendar.events.searchable.upcoming
        render :action => 'upcoming.rxml', :layout => false
      end
    end
#    cache_page nil, :permalink => params[:permalink]
  end
  
  def past 
    respond_to do |format|
      format.html do 
        @events = @calendar.events.searchable.past.paginate(:page => params[:page])
      end
      format.xml do 
        @events = @calendar.events.searchable.past
        render :action => 'upcoming.rxml', :layout => false
      end
    end
#    cache_page nil, :permalink => params[:permalink]
  end


  include ActionView::Helpers::JavaScriptHelper
  def total
    @states = @calendar.events.find(:all).collect {|e| e.state}.compact.uniq.select do |state|
      DaysOfAction::Geo::STATE_CENTERS.keys.reject {|c| :DC == c}.map{|c| c.to_s}.include?(state)
    end
    @event_count = @calendar.events.count
    respond_to do |format|
      format.js { headers["Content-Type"] = "text/javascript; charset=utf-8" }
      format.html { render :layout => false }
    end
  end
  
  def show
    @event = @calendar.events.find(params[:id], :include => [:blogs, {:reports => :attachments}])
    @map = cartographer_gmap(@event)
  end

  def new
    @event = Event.new params[:event]
    @user = User.new params[:user]
    @categories = @calendar.categories.map {|c| [c.name, c.id] }
    if current_theme
      cookies[:partner_id] = {:value => params[:partner_id], :expires => 3.hours.from_now} if params[:partner_id] 
      return if render_partner_signup_form
    end
  end

  def create
    @user = find_or_build_related_user params[:user ]
    @user.dia_group_key   = @calendar.host_dia_group_key if @user.dia_group_key.blank?
    @user.dia_trigger_key = @calendar.host_dia_trigger_key if @user.dia_trigger_key.blank?
    @event = @calendar.events.build(params[:event])

    if @user.valid? && @event.valid?
      @user.create_profile_image(params[:profile_image]) unless !params[:profile_image] || !params[:profile_image][:uploaded_data] || params[:profile_image][:uploaded_data].blank?
      @user.save!
      @event.host = @user
      @event.save!

      redirect_to params[:redirect] and return if params[:redirect]
      redirect_to @calendar.signup_redirect and return if @calendar.signup_redirect
      flash[:notice] = 'Your event was successfully created.'
      redirect_to :permalink => @calendar.permalink, :controller => 'events', :action => 'show', :id => @event
    else
      flash.now[:error] = 'There was a problem creating your event - please double check your information and try again.'
      @categories = @calendar.categories.map {|c| [c.name, c.id] }
      render :action => 'new'
    end
  end


  def rsvp
    @event = @calendar.events.find(params[:id])
    @user = find_or_build_related_user( params[:user] )
    
    @rsvp = Rsvp.new(:event_id => params[:id])
    if @user.valid? && @rsvp.valid?
      assign_democracy_in_action_tracking_code( @user, cookies[:partner_id] ) if cookies[:partner_id]
      @user.save
      @rsvp.user_id = @user.id
      @rsvp.save
      flash.now[:notice] = "<b>Thanks for the RSVP!</b><br /> An email confirming your RSVP has been sent to the email address you provided."
    else
      flash.now[:notice] = 'There was a problem registering your RSVP.'       
    end
    show  # don't call show on same line as render
    render(:action => 'show', :id => @event) && return
  end
  
  def reports
    if params[:id]
      @event = @calendar.events.find(params[:id], :include => :reports)
    else
      redirect_to :controller => :reports, :action => :index
    end
  end

  def other_state_events
    state = params[:event_state]
    unless state.blank?
      @other_state_events = @calendar.events.searchable.find_all_by_state(state)
      unless @other_state_events.empty?
        render(:partial => 'other_state_events', :layout => false) && return
      end
    end
    render :nothing => true    
  end

  def nearby_events
    postal_code = params[:postal_code]
    unless postal_code.blank?
      begin
        @nearby_events = @calendar.events.searchable.find(:all, :origin => postal_code, :within => 25)
      rescue GeoKit::Geocoders::GeocodeError
        render(:text => "", :layout => false) and return
      end
      unless @nearby_events.empty?
        render(:partial => 'shared/nearby_events', :layout => false) && return
      end
    end
    render :nothing => true
  end

  def host
    @event = @calendar.events.find(params[:id], :include => :host)
    @host = @event.host
  end

  def email_host
    @event = @calendar.events.find(params[:id], :include => :host)
    @host = @event.host
    if request.post?
      # if the hidden first_name field is set, it is likely bot request, so ignore
      return render(:action => 'show', :id => @event) unless params[:first_name].blank?
      if params[:from_email] && params[:from_email ] =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
        message = {
          :from => "\"#{params[:from_name]}\" <#{params[:from_email]}>", 
          :subject => params[:subject], 
          :body => params[:body] }

        #TODO(adam): Refactor! 

        if !@event.democracy_in_action_key
          UserMailer.deliver_message_to_host(message, @host)
        else
          client = HTTPClient.new 
          
          url = DemocracyInActionResource.api.urls['email'] || 
            'https://salsa.democracyinaction.org/email'

          url = URI.parse(url)

          message[:to] = @host.email
          message[:from] = params[:from_email]
          message[:content] = message[:body]
          client.post url, message
        end

        redirect_to( :controller => 'events', :action => 'show', :id => @event )        

      else
        flash.now[:notice] = "You must specify your email."
      end
    end
  end

  def index
    redirect_to( :permalink => @calendar.permalink, :controller => 'calendars', :action => 'show' ) and return unless params[:query] || params[:sort]

    origin = params[:query].delete(:origin) || params[:query].delete(:zip) if params[:query]
    options = origin ? {:origin => origin, :within => 50, :order => 'distance'} : {}
    options.merge!(:page => params[:page] || 1, :per_page => params[:per_page] || Event.per_page)
    @events = @calendar.events.prioritize(params[:sort]).searchable.by_query(params[:query]).paginate(:all, options)
    respond_to do |format|
      format.xml { render :xml => @events }
      format.json { 
        if params[:callback] && params[:target]
          render :json => "Event.observe( window, 'load', function() { #{params[:callback]}(#{@events.to_json( :methods => [ :start_date, :segmented_date ] )}, '#{params[:target]}'); });"
        elsif params[:callback]
          render :json => @events.to_json( :methods => [ :start_date, :segmented_date ] ), :callback => params[:callback]
        else
          render :json => @events
        end
      }
    end
  end
  
  def international
    @country_a3 = params[:id] || 'all'
    @country_code = CountryCodes.find_by_a3(@country_a3.upcase)[:numeric] || 'all'
    if @country_code == 'all'
      @events = @calendar.events.searchable.paginate(:all, :conditions => ["country_code <> ?", Event::COUNTRY_CODE_USA], :order => 'country_code, city, start', :page => params[:page])
    else
      @events = @calendar.events.searchable.paginate(:all, :conditions => ["country_code = ?", @country_code], :order => 'start, city', :page => params[:page])
    end
  end
 
  def search
    extract_search_params
    redirect_to(:permalink => @calendar.permalink, :controller => 'calendars', :action => 'show') and return unless @events
    @categories = @calendar.categories.find(:all).map{|c| [c.name.pluralize, c.id]}
    @categories.insert(0, ["All " + @calendar.permalink.capitalize, "all"]) unless @categories.empty?
    @category = @calendar.categories.find(params[:category]) if (params[:category] and not params[:category] == 'all')

    @map = cartographer_gmap(@events, :zip => params[:zip], :state => params[:state])
  end
  
  def simple
  end

  def extract_search_params
    if params[:zip] && !params[:zip].empty?
      by_zip
    elsif params[:state] && !params[:state].empty?
      by_state
    end
  end

  def by_zip
    @map_center = postal_code_center(params[:zip])
    flash.now[:notice] = "Could not find postal code" and return unless @map_center
    if params[:category] and not params[:category] == "all"
      @events = @calendar.events.searchable.find(:all, :origin => @map_center, :within => 50, :order => 'distance', :conditions => ['category_id = ?', params[:category]], :include => :calendar )
    else
      @events = @calendar.events.searchable.find(:all, :origin => @map_center, :within => 50, :order => 'distance', :include => :calendar )
    end
    @map_zoom = 12
    @auto_center = true
    @search_area = "within 50 miles of #{params[:zip]}"
  end

  def by_geo
    @events = @calendar.events.searchable.find(:all, :origin => [params[:lat], params[:lng]], :within => 50)
    @zips = ZipCode.find(:all, :origin => [params[:lat], params[:lng]], :within => 50, :order => 'distance')
    code = @zips.first.zip
    @district = Event.postal_code_to_district(code)
    @codes = @zips.collect {|z| z.zip}
    @events += @calendar.events.searchable.find(:all, :conditions => ["postal_code IN (?)", @codes])
    @events.uniq!
    @events.each {|e| e.instance_variable_set(:@distance_from_search, e.respond_to?(:distance) ? e.distance.to_f : @zips.find {|z| z.zip == e.postal_code}.distance.to_f) }
    @events = @events.sort_by {|e| e.instance_variable_get(:@distance_from_search)}
    render :layout => false
  end

  def by_state
    params[:state] ||= params[:id]
    if request.xhr?
      # this looks weird because by_state was traditionally not called directly, now it's being called by the map using xhr.  should refactor this.
      @events = @calendar.events.searchable.find(:all, :conditions => ["state = ?", params[:id]])
      render :partial => 'report', :collection => @events and return
    end
    @search_area = "in #{params[:state]}"
    if params[:category] and not params[:category] == "all"
      @events = @calendar.events.searchable.find(:all, :include => :calendar, :conditions => ["state = ? AND category_id = ?", params[:state], params[:category]])
    else
      @events = @calendar.events.searchable.find(:all, :include => :calendar, :conditions => ["state = ?", params[:state]])
    end
    @map_center = DaysOfAction::Geo::STATE_CENTERS[params[:state].to_sym]
    @map_zoom = DaysOfAction::Geo::STATE_ZOOM_LEVELS[params[:state].to_sym]
  end
  
  def description
    @event = @calendar.events.find(params[:id])
    render :update do |page|
      page.replace_html 'report_event_description', "<h3>Event Description</h3>#{@event.description}"
      page.show 'report_event_description'
    end
  end

  protected

    def find_or_build_related_user( user_params )
      user = User.find_or_initialize_by_site_id_and_email(Site.current.id, user_params[:email]) 
      user_params.reject! {|k,v| [:password, :password_confirmation].include?(k.to_sym)}
      user_params[:partner_id] ||= cookies[:partner_id] if cookies[:partner_id]
      user.attributes = user_params
      user
    end

    def render_partner_signup_form
      if cookies[:partner_id] && is_partner_form(cookies[:partner_id])
        render :template => "events/partners/#{cookies[:partner_id]}/new"
      end
    end
  
    def assign_democracy_in_action_tracking_code( user, code )
      return unless code
      user.democracy_in_action ||= {}
      if @calendar.id == 8 # momsrising.fair-pay  #credit: seth walker
        user.democracy_in_action['supporter_custom'] ||= {}
        user.democracy_in_action['supporter_custom']['VARCHAR3'] = code
      else
        user.democracy_in_action['supporter'] ||= {}
        user.democracy_in_action['supporter']['Tracking_Code'] = "#{code}_rsvp"
      end
    end

    #hmm, why is this here? oh yes, for objects retrieved from memcache?
    def autoload_missing_constants
      yield
#    rescue ArgumentError, MemCache::MemCacheError => error
    rescue ArgumentError
      lazy_load ||= Hash.new { |hash, key| hash[key] = true; false }
      retry if error.to_s.include?('undefined class') && 
        !lazy_load[error.to_s.split.last.constantize]
      raise error
    end  

  private
    def is_partner_form(form)
      File.exist?("themes/#{current_theme}/views/events/partners/#{form}")
    end
end
