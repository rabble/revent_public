class Admin::EventsController < AdminController
  active_scaffold :events do |config|
  	config.list.columns =  
  	    [:start, :created_at, :name, :city, :state, :latitude, :longitude, :host, :category, :private, :rsvps, :reports, :calendar]
  	config.show.columns =  
  	    [:start, :end, :created_at, :name, :description, :directions, :location, :city, :state, :postal_code, :latitude, :longitude, :host, :private, :tags, :category, :reports, :calendar]
  	config.update.columns =  
  	    [:start, :name, :description, :directions, :location, :city, :state, :postal_code, :private]
  	config.actions.exclude :create
  	config.actions.exclude :update
   	config.action_links.add 'manage', 
   	  {:label => 'Manage', :controller => 'account/events', :action => 'show', :type => :record, :inline => false} 
  	config.columns[:attendees].label = "RSVPs"
    config.columns[:tags].clear_link    
    config.columns[:category].clear_link    
  	config.columns[:rsvps].clear_link
    config.columns[:reports].clear_link    
    config.columns[:calendar].clear_link  
  	config.list.sorting = [{:start => :desc}]
  	columns[:rsvps].sort_by :method => 'rsvps.length'
  	columns[:reports].sort_by :method => 'reports.length'
  	columns[:host].sort_by :method => 'host.name'
  	columns[:private].list_ui = :checkbox
  end
  
  def index
    # need this since active scaffold is embeded in order to provide export link
  end

  def list
    if request.format == Mime::XML
      xml_options = { :include => 
                      { :attendees => { :include => :custom_attributes },
                        :host =>      { :include => :custom_attributes }, 
                        :reports =>   { :include => {:user => {:include => :custom_attributes}}}
                      },
                      :except => [:crypted_password, :activation_code, :salt, :password_reset_code]
                    }
      if params[:updated_since] && start_time = Time.parse( params[:updated_since ] )
        @events = @calendar.events.find_updated_since(start_time)
      else
        @events = @calendar.events
      end
      render :xml => @events.to_xml(xml_options)
    else
      super
    end
  end

  def conditions_for_collection
    ["events.calendar_id IN (#{(@calendar.calendar_ids << @calendar.id).join(',')})"]
  end
  
  def export
    @events = @calendar.events.find(:all, :include => :reports, :order => 'start')
    require 'fastercsv'
    string = FasterCSV.generate do |csv|
      csv << ["Event ID", "Event Name", "Start Date", "Start Time", "Address", "City", "State", 
       	      "Postal Code", "District", "Host Name", "Host Email", "Host Phone", 
	            "Host Address", "High Attendees", "Low Attendees", "Average Attendees", "Organized/Sponsored by", "Created At"]
      @events.each do |event|
        host = event.host
        csv << [event.id, event.name, event.start.strftime("%m/%d/%Y"), event.start_time, 
                event.location, event.city, event.state, event.postal_code, event.district, 
                (host ? host.full_name : nil), (host ? host.email : nil), (host ? host.phone : nil), 
                (host ? host.address : nil), event.attendees_high, event.attendees_low, event.attendees_average,
                event.organization, event.created_at.to_s(:db)]
      end
    end
    send_data(string, :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@calendar.permalink}_events.csv")
  end  

  def featured_images
    collect_featured_images
#    require 'starling_client'
    require 'starling'
    queue = Starling.new 'localhost:22122'
    timestamp = Time.now.strftime("%y%m%d_%H%M%S") 
    @latest = File.join(RAILS_ROOT,'public','featured_images_' + timestamp + '.zip')
    queue.set 'images', {:timestamp => timestamp, :images => @featured_images, :site => Site.current}

#    render :inline => "generated zip successfully, please download it <%= link_to 'here', '/#{zip_file_name}' %>"
#    send_data result, :filename => 'featured_images.zip'
  end

  def mail_merge
    @calendar = Calendar.find_by_permalink(params[:permalink])
    render :layout => false
  end

private  
  def zip_em_up(timestamp)
    image_names = []
    image_dir = File.join(RAILS_ROOT, 'public', 'featured_images_' + timestamp)
    result = `mkdir #{image_dir}` if not File.exists?(image_dir)
    @featured_images.each do |a|
      local_filename = File.join(image_dir, a.report.event.state + "_" + a.report.event.id.to_s + File.extname(a.public_filename))
      next if Dir[File.join(RAILS_ROOT, 'public', 'featured_images*', '*')].map {|full_path| File.basename(full_path)}.include?(File.basename(local_filename))
      result = `curl #{a.public_filename} > #{local_filename}`
      image_names << local_filename
    end
    return if image_names.empty?
    image_names = image_names.join(' ')
    @latest = File.join(RAILS_ROOT,'public','featured_images_' + timestamp + '.zip')
    result = `zip -j #{@latest} #{image_names}`
  end

  def collect_featured_images
    events = @calendar.events.find(:all, :include => {:reports => :attachments}, :conditions => "attachments.id")
    @featured_images = []
    events.each do |e|
      next unless e.reports
      attachments = e.reports.collect {|r| r.attachments}.flatten.sort_by {|a| a.primary ? 1 : 0}
      next if attachments.empty?
      primary = attachments.first if attachments.first.primary
      primary ||= e.reports.first.attachments.first
      primary ||= attachments.first
      @featured_images << primary
    end
#    send_data `zip -j - #{package.collect {|a| a.full_filename}.join(' ')}`, :filename => 'featured_images.zip'
  end

end
