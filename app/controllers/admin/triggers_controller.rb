class Admin::TriggersController < AdminController 
	active_scaffold :trigger do |config|
    config.label = "Email Response Triggers"
  	config.columns = [:name, :calendar, :site, :from_name, :from, :reply_to, :bcc, :subject, :email_plain, :email_html]
    config.update.columns = [:name, :calendar, :from_name, :from, :reply_to, :bcc, :subject, :email_plain, :email_html]
    config.create.columns = [:name, :calendar, :from_name, :from, :reply_to, :bcc, :subject, :email_plain, :email_html]
  	config.columns[:calendar].form_ui = :select     # just want drop down on form (no crazy subforms) 	
  	config.columns[:calendar].clear_link            # just want calendar name on list (no links)
#  	config.columns[:calendar].description = "Calendar triggers over-ride 'All Calendars' triggers"
  	config.columns[:calendar].label = "Apply to Calendar"
  	config.columns[:name].label = "Email Trigger"
  	config.columns[:from].label = "From Email Address"
  	config.columns[:from_name].label = "From Name"
  	config.columns[:email_plain].label = "Message (Plain Text)<br /><br />The following tokens are available to insert event information (must include square-backets):<br /><br />[EVENT_NAME], [EVENT_CITY], [EVENT_STATE], [EVENT_ADDRESS], [EVENT_START_DATE], [EVENT_START_TIME], [EVENT_LINK], [SIGNUP_LINK], [MANAGE_LINK], [REPORT_LINK], [NEW_REPORT_LINK], [HOST_NAME], [HOST_FIRST_NAME], [HOST_LAST_NAME], [HOST_EMAIL]"
  	config.columns[:email_html].label = "Message (HTML)<br /><br />All event information tokens listed above are also available here."
  	config.list.columns = [:name, :calendar, :subject, :from_name, :from]
#  	config.list.sorting = [{:calendar => :asc}, {:name => :asc}]
  end

  def before_create_save(trigger)
    # only set the site if calendar is not set
    trigger.site_id = Site.current.id unless trigger.calendar_id
  end

  def conditions_for_collection
    @site = Site.current
    ["triggers.site_id = ? OR triggers.calendar_id IN (?)", @site.id, @site.calendar_ids]
  end
end

