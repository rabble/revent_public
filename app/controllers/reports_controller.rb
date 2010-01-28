class ReportsController < ApplicationController

  caches_page_unless_flash :show, :index, :flashmap, :list, :new, :press, :video, :lightbox
  cache_sweeper :report_sweeper, :only => [ :create, :update, :destroy, :publish, :unpublish ]
  verify :method => :post, :only => :create, :redirect_to => {:action => 'index'}

  def index
    # events get pulled up by ReportsController#flashmap
  end

  def video
    if params[:tag]
      tag = Tag.find_by_name params[:tag]
      @embeds = tag.embeds.find(:all, :include => {:report => :event}, :conditions => "events.calendar_id = #{@calendar.id}")
      @reports = @embeds.collect {|e| e.report}.uniq
    else
      @reports = @calendar.reports.published.find(:all, :conditions => "embeds.id", :include => [:event, :embeds])
    end
  end

  def photos
    if params[:tag]
      tag = Tag.find_by_name params[:tag]
      @photos = tag.attachments.find(:all, :include => {:report => :event}, :conditions => "events.calendar_id = #{@calendar.id}")
    else
      @photos = @calendar.reports.published.find(:all, :include => [:attachments, :event], :conditions => "attachments.id").collect {|r| r.attachments}.flatten
    end
  end

  def press
    @press_links = @calendar.reports.published.find(:all, :include => [:event, :press_links], :conditions => "press_links.id").collect {|r| r.press_links}.flatten
  end

  def flashmap
    # all events should have lat/lng or fallback lat/lng; remove ones that don't just in case
    @events = @calendar.events.searchable.find(:all, :select => [:name, :city, :state], :conditions => ["(latitude <> 0 AND longitude <> 0 AND country_code = ?)", Event::COUNTRY_CODE_USA], :include => :reports)
    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  def scrolling_photos 
    # not quite ready to scroll dynamic content
    redirect_to :action => 'index' and return
    @reports = @calendar.reports.published.find(:all, :include => [:attachments], :conditions => "attachments.id AND attachments.content_type = 'image/jpeg'", :limit => 5)
    respond_to do |format|
      format.xml {render :layout => false}
    end
  end

  def rss
    @reports = @calendar.reports.published(:all, :order => "updated_at DESC")
    respond_to do |format|
      format.xml { render :layout => false }
    end
  end

  def list
    @reports = @calendar.reports.published.paginate(:all, :include => :attachments, 
      :order => 'reports.created_at DESC', :page => params[:page], :per_page => 20)

    # temporary fix to get everythingscool layout to load here
    reports_layout = File.join(RAILS_ROOT, "themes/#{current_theme}/views/layouts/reports.rhtml")
    render(:layout => 'reports') if File.exists?(reports_layout)
  end

  def international 
    @country_a3 = params[:id] || "all"
    @country_code = CountryCodes.find_by_a3(@country_a3)[:numeric] || "all"
    if @country_code == "all"
      @events = @calendar.events.searchable.paginate(:all, :include => {:reports => :attachments}, 
        :conditions => "reports.id AND reports.status = '#{Report::PUBLISHED}' AND country_code <> '#{Event::COUNTRY_CODE_USA}'", :order => "reports.id", :page => params[:page], :per_page => 20)
    else
      @events = @calendar.events.searchable.paginate(:all, :include => {:reports => :attachments}, 
        :conditions => ["reports.id AND reports.status = '#{Report::PUBLISHED}' AND country_code = ?", @country_code], :order => "reports.id", :page => params[:page], :per_page => 20)
    end
    @reports = @events.collect {|e| e.reports.first}
  end
 
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def show
    @event = @calendar.events.find(params[:event_id], :include => {:reports => :attachments}, :order => 'reports.position')
  end

  include ActionView::Helpers::TextHelper
  def new 
    redirect_to(home_url) && return if @calendar.archived?

    raise(ActionController::RoutingError.new "No route matches \"#{request.request_uri}\" with {:method=>#{request.request_method}}") if params[:id] && !(params[:id] =~ /\d+/) #this should be done in routes
    @report = Report.new(:event_id => params[:id])
    if params[:service] && params[:service_foreign_key]
      @report.event = Event.find_or_import_by_service_foreign_key(params[:service_foreign_key])
    end
  end

  def create
    redirect_to(home_url)  unless params[:honeypot].empty? 
    @report = Report.new(params[:report].merge(:akismet_params => Report.akismet_params(request)))
    if @report.valid?
      begin 
        @report.make_local_copies!
        ReportWorker.async_save_report( @report )
      rescue Workling::WorklingError
        logger.info("Workling unable to connect.")
        @report.save
      end
      flash[:notice] = 'Report was successfully created.'
      if @calendar.report_redirect
        redirect_to @calendar.report_redirect
      else
        redirect_to :permalink => @calendar.permalink, :action => 'index'
      end
    else
      flash[:notice] = 'An error occurred while trying to create your report.'
      render :action => 'new'
    end 
  end

  def lightbox
    @attachment = Attachment.find(:first, :conditions => ["attachments.parent_id = ? AND attachments.thumbnail = 'lightbox'", params[:id]], :include => :parent) || raise(ActiveRecord::RecordNotFound)
    render :layout => false
  end

  def share 
    @event = Event.find(params[:id])
    render :layout => false
  end

  def widget
    if params[:id]
      @report = Report.published.find(params[:id], :include => :attachments)
      @image = @report.attachments.first
    else
#      @image = Attachment.find(:first, :joins => 'LEFT OUTER JOIN reports ON attachments.report_id = reports.id', :conditions => ['report_id AND reports.status = ?', Report::PUBLISHED], :order => 'RAND()')
      @image = Attachment.find(:first, :include => [:report => :event], :conditions => ['report_id AND reports.status = ?', Report::PUBLISHED], :order => 'RAND()')
      @report = @image.report
    end
    render :layout => false
  end

  def do_zip_search
    @zip = ZipCode.find_by_zip(params[:zip])
#    flash.now[:notice] = "Could not locate that zip code" and return unless @zip
    @search_results_message = "Sorry, we don't have that zip code in our database, try a different one from near by." and return unless @zip
    @zips = @zip.find_objects_within_radius(100) do |min_lat, min_lon, max_lat, max_lon|
      ZipCode.find(:all, 
                   :conditions => [ "(latitude > ? AND longitude > ? AND latitude < ? AND longitude < ? ) ", 
                        min_lat, 
                        min_lon, 
                        max_lat, 
                        max_lon])
    end
    @reports = @calendar.reports.published.paginate(:all, :include => :attachments, :conditions => ["events.postal_code IN (?)", @zips.collect{|z| z.zip}], :order => "reports.created_at DESC", :page => params[:page], :per_page => 20) 
    @codes = @zips.collect {|z| z.zip}
#    @reports = @reports.sort_by {|r| @codes.index(r.event.postal_code)}
    @reports.each {|r| r.instance_variable_set(:@distance_from_search, @zips.find {|z| z.zip == r.event.postal_code}.distance_to_search_zip) }
    @search_results_message = "Showing reports within 100 miles of #{@zip.zip}"
    @search_params = {:zip => @zip.zip}
  end

  def do_state_search
    @reports = @calendar.reports.published.paginate(:all, :include => :attachments, :conditions => ["events.state = ?", params[:state]], :order => "events.state, events.city", :page => params[:page], :per_page => 20)
    @search_results_message = "Showing reports in #{params[:state]}"
    @search_params = {:state => params[:state]}
  end

  def search
    redirect_to :action => 'index' and return unless params[:zip] || params[:state]
    if params[:zip] && !params[:zip].empty?
      do_zip_search
    elsif params[:state] && !params[:state].empty?
      do_state_search
    end
    unless @reports
      list
      render :action => 'list' and return
    end
    render :action => 'list'
  end

  def slideshow
    @event_id = params[:id].to_i
    if @flickr_user_id = Site.current.flickr_user_id
      @slideshow_url = "http://www.flickr.com/slideShow/index.gne?user_id=#{@flickr_user_id}"
      @slideshow_url += "&tags=#{@calendar.flickr_tag}#{params[:id]}" if @calendar.flickr_tags
    end
  end

  def featured
    if params[:id]
      @reports = @calendar.reports.featured.find(:all, :conditions => ["events.state = ?", params[:id]], :include => :event, :limit => 7, :order => 'reports.created_at DESC')
    else
      @reports = @calendar.reports.featured.find(:all, :include => :event, :limit => 7, :order => 'reports.created_at DESC')
    end
    render :layout => false
  end

  def redirect_to_show_with_permalink
    @event = Event.find(params[:event_id])
    redirect_to report_url(:host => @event.calendar.site.host, :permalink => @event.calendar.permalink, :event_id => @event.id), :status => :moved_permanently
  end
end
