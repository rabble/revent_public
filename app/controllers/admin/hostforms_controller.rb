class Admin::HostformsController < AdminController 
	active_scaffold :hostforms do |config|
    config.label = "Event Host Sign Up Forms"
  	config.columns = [:calendar, :title, :intro_text, :event_info_text,  :pre_submit_text, :thank_you_text,  :dia_trigger_key, :dia_group_key, :dia_user_tracking_code, :dia_event_tracking_code, :redirect]  	
  	config.list.columns = [:title, :calendar, :site]
  	columns[:calendar].ui_type = :select
  end

  def conditions_for_collection
    [ "hostforms.site_id = ?", Site.current.id ]
  end
  
  def before_create_save(hostform)
    hostform.site_id = Site.current.id
  end
end


