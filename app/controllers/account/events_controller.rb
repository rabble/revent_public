class Account::EventsController < ApplicationController
  session :disabled => false

  # login_required calls authorized? (at bottom of this file) 
  # which sets up @event for any method in this controller to use
  before_filter :login_required   
  cache_sweeper :event_sweeper, :only => [:update, :remove, :upload]
  #verify :method => :post, :only => [:update, :remove, :upload], :redirect_to => {:action => 'index'}

  def index
    @hosting = current_user.events
    @attending = current_user.attending
  end

  def show
    extend ActionView::Helpers::TextHelper
    @nearby_events = @event.nearby_events
    @blog = Blog.new(:event => @event)
    @event.render_scripts   # render letter/call scripts
    require 'ostruct'
    @invite = OpenStruct.new(:recipients => nil, :subject => @event.calendar.attendee_invite_subject, :body => @event.calendar.attendee_invite_message)
  end

  def upload
    if !params[:attachment][:uploaded_data].blank? && @event.attachments.create!(params[:attachment])
      flash[:notice] = "Upload successful"
    else
      flash[:error] = "Upload failed"
    end
    redirect_to :action => 'show', :id => @event
  end

  def update
    redirect_to :action => 'show', :id => @event and return unless params[:event]
    @event.update_attributes!(params[:event])
    if params[:event][:letter_script] || params[:event][:call_script]
      update_campaign_scripts(@event) if params[:event][:letter_script]
      flash[:notice] = 'Invitation script(s) updated.'
    else
      flash[:notice] = 'Event updated'
    end
    logger.info 'updated attributes'
    redirect_to :action => 'show', :id => @event
  rescue ActiveRecord::RecordInvalid
    logger.info 'event invalid'
    show
    render :action => 'show', :id => @event
  end
  
  def update_campaign_scripts(event)
    objects = DemocracyInActionObject.find(:all, :from => "democracy_in_action_objects as d",
      :conditions => ["d.table = ? AND associated_type = ? AND associated_id = ?", 'campaign', 'Event', event.id])
    objects.each do |o|
      c = DemocracyInActionCampaign.find(o.key)
      c.Suggested_Content = event.letter_script
      c.save
    end
  end  

  def invite
    unless (params[:invite] && params[:invite][:recipients] && params[:invite][:subject] && params[:invite][:body])
      flash[:notice] = 'Must provide recipient emails (separated by commas), subject, and message for invitations.'
      redirect_to :action => 'show', :id => @event and return
    end
    UserMailer.deliver_invite(current_user.email, @event, params[:invite])
    flash[:notice] = 'Invites delivered'
    redirect_to :action => 'show', :id => @event
  end

  def message
    UserMailer.deliver_message(current_user.email, @event, params[:message])
    flash[:notice] = 'Email delivered'
    redirect_to :action => 'show', :id => @event
  end

  def remove
    @rsvp = @event.rsvps.find(:first, :conditions => {:user_id => current_user.id})
    @rsvp.destroy
    redirect_to :action => 'index'
  end

  def attendees
    require 'fastercsv'
    string = FasterCSV.generate do |csv|
      csv << ["Email", "First_Name", "Last_Name", "Phone"]
      (@event.attendees || @event.to_democracy_in_action_event.attendees.collect {|a| User.new :email => a.Email, :first_name => a.First_Name, :last_name => a.Last_Name, :phone => a.Phone}).each do |sup|
        csv << [sup.email, sup.first_name, sup.last_name, sup.phone]
      end
    end
    send_data(string, :type => 'text/csv; charset=utf-8; header=present', :filename => "event_#{@event.id}_attendees.csv")
  end

  protected
  def authorized?
    return true if %w(index).include?(action_name)
    @event = Event.find(params[:id])
    return true if current_user.admin?
    if %w(remove).include?(action_name)
      return true if current_user.attending.include?(@event)
    end
    return true if current_user.events.include?(@event)
    false
  end
end
