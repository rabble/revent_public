# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include HoptoadNotifier::Catcher
  rescue_from ActionController::UnknownAction, :with => :unknown

  before_filter :login_from_cookie
  session :session_key => '_daysofaction_session_id'
#  session :off, :if => Proc.new { |req| !(true == req.parameters[:admin]) }

  before_filter  :clean, :set_site, :set_calendar, :set_cartographer_keys, :set_cache_root
  helper_method  :site

  def set_cache_root
	  self.class.page_cache_directory = File.join([RAILS_ROOT, (RAILS_ENV == 'test' ? 'tmp' : 'public'), 'cache', site.host])
	end

  def set_cartographer_keys
    Cartographer::Header.load_configuration(File.join(Site.current_config_path, 'cartographer-config.yml'))
  end

  def clean
    Site.current = nil
    true
  end

  def site
    Site.current
  end

  def set_site
    Calendar #need this for instantiating from memcache, could also override autoload_missing_constants like we do in events_controller
    Site.current ||= Cache.get("site_for_host_#{request.host}") { Site.find_by_host(request.host) }  #, :include => :calendars) }
    raise 'no site' unless site
  end

  def set_calendar
    @calendar = site.calendars.detect {|c| params[:permalink] == c.permalink } || site.calendars.detect {|c| c.current?} || site.calendars.first    
    raise 'no calendar' unless @calendar
  end

  theme :get_theme
  def get_theme
    return @calendar.theme if @calendar && @calendar.theme
    site.theme if site
  end

  def render_optional_error_file(status_code)
    status = interpret_status(status_code)
    theme_path = File.join(Theme.path_to_theme(current_theme), "#{status[0,3]}.html")
    path = "#{RAILS_ROOT}/public/#{status[0,3]}.html"
    if File.exist?(theme_path)
      render :file => theme_path, :status => status
    elsif File.exist?(path)
      render :file => path, :status => status
    else
      head status
    end
  end

  def self.caches_page_unless_flash(*args)
    return unless perform_caching
    actions = args.map(&:to_s)
    after_filter { |c| c.cache_page if actions.include?(c.action_name) && c.send(:flash)[:error].blank? && c.send(:flash)[:notice].blank? }
  end

  private

  def unknown
    case action_name
    when /;/
      render_optional_error_file(404) && return
    end

    case request.path
    when /\.php$/
      render_optional_error_file(404) && return
    end

    raise
  end
end
