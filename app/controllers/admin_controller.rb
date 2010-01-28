class AdminController < ApplicationController
  before_filter :login_required, :except => 'login'
  before_filter :instantiate_controller_and_action_names

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:email], params[:password])
    if current_user
      if params[:remember_me] == "1" && current_user.respond_to?(:remember_me)
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => '/admin', :action => 'index')
      flash[:notice] = "Logged in successfully"
    else
      flash[:notice] = "Login failed"
    end
  end

  def instantiate_controller_and_action_names
    @current_action = action_name
    @current_controller = controller_path
  end
  
  # over-ride set_calendar
  # alright, so here's the deal. when we hit /admin/<permalink>/events
  # we'll hit set_calendar (below) where we save the permalink. however,
  # we'll get 302'd (redirected) to an active_scaffold method without
  # the permalink in the params, so need to save it in the session (for
  # use in EventsController::conditions_for_selection). 
  #
  # tried using cookies, but didn't seem to work correctly (maybe new cookie 
  # not being sent on 302, not sure). by using session (which is stored on 
  # server-side) we guarantee that regardless of 302, we have the permalink
  def current_permalink
    return if current_user.nil?
    if params[:permalink]
      session["#{current_user.id}_permalink"] = params[:permalink]
    else
      session["#{current_user.id}_permalink"]
    end
  end

  def set_calendar
    @calendar = site.calendars.detect {|c| current_permalink == c.permalink} ||
                site.calendars.detect {|c| c.current?} ||
                site.calendars.first
    raise 'no calendar' unless @calendar
  end
  
protected
  def authorized?
    return true if current_user.admin?
    flash[:notice] = "Must be an administrator to access this section"
    return false
  end

  def access_denied
    respond_to do |accepts|
      accepts.html do
        store_location
        redirect_to :controller => '/admin', :action => 'login'
      end
    end
  end
end
