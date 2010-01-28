class Admin::ReportsController < AdminController
  cache_sweeper :report_sweeper, :only => [:create, :update, :destroy]

  active_scaffold :reports do |config|
    config.columns = [:created_at, :event, :user, :attendees, :status, :featured, :attachments_count, :embeds_count ]#, :attachments, :embeds]
    config.show.columns = [:created_at, :event, :reporter_email, :user, :text, :attendees, :status, :featured, :attachments, :embeds]
    config.update.columns = [:status, :featured, :text, :attendees]
    config.columns[:attendees].label = "Estimated attendance"
    config.columns[:attachments].label = "# of Attachments"
    config.columns[:embeds].label = "# of Embeds"
    config.columns[:user].label = "Reporter"
    config.columns[:attachments].clear_link    
    config.columns[:embeds].clear_link    
  	columns[:featured].list_ui = :checkbox
  	columns[:featured].form_ui = :checkbox
  	config.list.sorting = [{:created_at => :desc}]
  	config.actions.exclude :create
    #config.action_links.add 'edit', 
    #  {:label => 'Edit', :controller => 'account/reports', :action => 'show', :type => :record, :inline => false} 
  end

  def conditions_for_collection
    ["events.calendar_id IN (#{(@calendar.calendar_ids << @calendar.id).join(',')})"]
  end

  def index
  end 
  
  REPORT_IMAGE_PUBLIC = 'reportimages' 
  REPORT_IMAGE_ROOT   = File.join(RAILS_ROOT, 'public', REPORT_IMAGE_PUBLIC)
  REPORT_IMAGE_PREFIX = "images_"

  def export_images
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S") 
    @reports = @calendar.reports.find(:all, :include => :attachments, :conditions => "attachments.id") 
    images = @reports.collect {|r| r.attachments}.flatten
    require 'starling'
    queue = Starling.new('localhost:22122')
    queue.set('images', {:permalink => @calendar.permalink, :timestamp => timestamp, :images => images, :site_id => Site.current.id})
    redirect_to(:action => 'zipped_images', :timestamp => timestamp)
  end

  # hard to distinguish difference between zip 
  # file not ready and no new files to zip 
  def zipped_images
    @timestamp = params[:timestamp]
    zip_file = File.join(REPORT_IMAGE_ROOT, @calendar.permalink, REPORT_IMAGE_PREFIX + @timestamp + '.zip')
    if File.exists?(zip_file)
      @zip_file = {}
      @zip_file[:path] = request.protocol + File.join(request.host, REPORT_IMAGE_PUBLIC, @calendar.permalink, REPORT_IMAGE_PREFIX + @timestamp + '.zip')
      @zip_file[:size] = File.size(zip_file)
    end
    @zip_files = Dir[File.join(REPORT_IMAGE_ROOT, @calendar.permalink, '*.zip')] - [zip_file]
    @zip_files = @zip_files.map do |file| 
      {:path => request.protocol + File.join(request.host, REPORT_IMAGE_PUBLIC, @calendar.permalink, File.basename(file)), 
       :size => (File.size(file)/1024/1024) }
    end
  end

  def self.create_dir(path)
    Dir.mkdir(path) unless File.exists?(path) 
    path
  end

  #local_filename = File.join(image_dir, a.report.event.state + "_" + a.report.event.id.to_s + File.extname(a.public_filename))
  def self.zip_em_up(permalink, timestamp, attachments)
    path      = create_dir(File.join(REPORT_IMAGE_ROOT))
    perm_path = create_dir(File.join(path, permalink))
    files_already_zipped = Dir[File.join(perm_path, REPORT_IMAGE_PREFIX + '*', '*')].map{|f| File.basename(f)}
    full_path = create_dir(File.join(perm_path, REPORT_IMAGE_PREFIX + timestamp))

    files_to_zip = []
    attachments.each do |a|
      local_filename = File.join(full_path, a.report_id.to_s + '_' + File.basename(a.public_filename))
      next if files_already_zipped.include?(File.basename(local_filename))
      remote_filename = a.public_filename
      result = `curl #{a.public_filename} > #{local_filename}` 
      files_to_zip << local_filename
    end
    if files_to_zip.empty?
      Dir.rmdir(full_path)
      return
    end
    zipfile = File.join(perm_path, REPORT_IMAGE_PREFIX + timestamp + '.zip')
    result = `zip -j #{zipfile} #{files_to_zip.join(' ')}`
  end

private  
  def collect_featured_images
    events = @calendar.events.find(:all, :include => {:reports => :attachments}, :conditions => "attachments.id")
    @images = []
    events.each do |e|
      next unless e.reports
      attachments = e.reports.collect {|r| r.attachments}.flatten.sort_by {|a| a.primary ? 1 : 0}
      next if attachments.empty?
      primary = attachments.first if attachments.first.primary
      primary ||= e.reports.first.attachments.first
      primary ||= attachments.first
      @images << primary
    end
  end
end
