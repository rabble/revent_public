class AccountController < ApplicationController
  session :disabled => false
  before_filter :login_required, :only => :profile

  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
    redirect_to :action => 'profile'
  end

  def activate
    if current_user
      flash[:notice] = "You are already logged in"
      redirect_to :controller => 'account/events', :action => 'index'
      return
    end
      
    if params[:id]
      @user = User.find_by_activation_code(params[:id]) 
      if @user and @user.activate
        self.current_user = @user
        redirect_to(:action => 'reset_password')
        flash[:notice] = "Your account has been activated." 
      else
        flash[:error] = "Unable to activate the account. If you do not remember your password, you will need to request a password reset."
        redirect_to :action => 'forgot_password'
      end
    else
      flash.clear
    end
  end

  def send_activation
#    user = DemocracyInActionSupporter.find(:first, :conditions => "Email='#{params[:email]}'")
    user = User.find_by_site_id_and_email(Site.current, params[:email]) if params[:email]
    if !user
      flash[:notice] = "Email not found"
      redirect_to login_url
      return
    end
    if user.activated_at 
      user.forgot_password
      user.save
      flash[:notice] = "Your account was already active.<br />  If you would like to reset your password, click on 'Forgot Your Password?' below" 
    else
      UserMailer.deliver_activation(user)
      flash[:notice] = 'An email with an account activation link has been sent to you.'
    end
    redirect_to login_url
  end

  def profile
    @user = current_user
    return unless request.post?
    @user.update_attributes(params[:user])
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.create_profile_image(params[:profile_image]) unless params[:profile_image][:uploaded_data].blank?
    if @user.save
      flash[:notice] = "Your profile has been updated"
      redirect_to :controller => '/account/events', :action => 'index'
    else
      flash[:notice] = "There was an error updating your profile"
    end
  end

=begin
  def events
    @user = current_user
    @event = Event.find(params[:id])
    if current_user.supporter_KEY != @event.dia_event.supporter_KEY
      flash[:error] = 'You can only edit events you are hosting'
      redirect_to :action => 'profile' and return
    end
  end
=end

  def old_events
    @user = current_user
    @dia_events = DemocracyInActionEvent.find(:all, :conditions => "supporter_KEY = #{@user.supporter_KEY}")
    @events = Event.find_all_by_service_foreign_key(@dia_events.collect {|e| e.event_KEY})
    return unless request.post?
    # do update
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:email], params[:password])
    if current_user
      if params[:remember_me] == "1" && current_user.respond_to?(:remember_me)
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_to(:controller => '/account/events')
      flash[:notice] = "Logged in successfully"
    else
      flash[:notice] = "Login failed"
    end
  end

  def signup
    @user = User.new(params[:user])
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    return unless request.post?
    @user.save!
    self.current_user = @user
    redirect_back_or_default(:controller => '/account', :action => 'profile')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end

  #XXX: look at EventsController#create
  def new_signup
#    @user = User.new(params[:user])
    @supporter = DemocracyInActionSupporter.new(params[:democracy_in_action_supporter])
    @event = Event.new(params[:event])
    return unless request.post?
    @event.start = Time.local(params[:start][:year] || 2007, params[:start][:month] || 4, params[:start][:day] || 14, params[:time])
    raise @event.inspect
    #<input type="hidden" value="0,First_Name,Last_Name,Email,Phone," name="required" />
    #distributed_event_KEY = 239
    #email_trigger_KEYS=2590
    #Tracking_Code
    #Maximum_Attendees = 100
    #required = "Event_Name,Description,Start,End,Address,City,State,Directions,Zip,Maximum_Attendees"
    #updateRowValues=true
    #trigger="On New Distributed Event"
    #Status=Unconfirmed
    #add to group: 50838
    @user.save!
    self.current_user = @user
    redirect_back_or_default(:controller => '/account', :action => 'profile')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  def logout
    self.current_user.forget_me if logged_in? && self.current_user.respond_to?(:forget_me)
    cookies.delete :auth_token
    reset_session
    redirect_back_or_default(home_url)
  end

  def forgot_password
    return unless request.post?
    if @user = User.find_by_site_id_and_email(Site.current, params[:email])
      @user.forgot_password
      @user.save
      flash[:notice] = "A password reset link has been sent to your email address" 
      redirect_to login_url
    else
      flash[:notice] = "Could not find a user with that email address" 
    end
  end

  # this method is used both for initially setting a users password
  # and for resetting a users password if they have forgotten it.
  def reset_password
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    @password_reset_code_present = true if @user
    @user ||= current_user
    raise if @user.nil?
    return if @user unless params[:password]
    if (params[:password] == params[:password_confirmation])
      self.current_user = @user #for the next two lines to work
      current_user.password_confirmation = params[:password_confirmation]
      current_user.password = params[:password]
      current_user.activated_at ||= Time.now.utc
      @user.reset_password if @password_reset_code_present
      flash[:notice] = current_user.save ? "Password reset" : "Password not reset" 
    else
      flash[:notice] = "Password mismatch" 
    end  
    redirect_back_or_default(:controller => '/account', :action => 'index') 
  rescue
    logger.error "Invalid Reset Code entered" 
    flash[:notice] = "Sorry - That is an invalid password reset code. Please check your code and try again. (Perhaps your email client inserted a carriage return?" 
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end
end
