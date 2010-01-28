module Hacks
#class SiteController < ApplicationController
#  session :disabled => false
#  before_filter :login_required, :except => :map
#  access_control :DEFAULT => 'admin'

  def self.cp_to_print(a)
    print = a.thumbnails.find_by_thumbnail('print')
    unless print
      print = a.create_or_update_thumbnail(:print, '432>x288>')
    end
    event = a.event || a.report.event
    return if event.nil?
    host = event.dia_event.supporter_KEY
    return if host.nil?
    extension_start = a.filename.rindex('.')
    if extension_start
      extension = a.filename[a.filename.rindex('.')..a.filename.size]
    else
      extension = ''
    end
    FileUtils.cp(File.expand_path(print.full_filename),File.expand_path(File.join(RAILS_ROOT,'tmp','export','print_images',"#{host}#{extension}")))
  end

  def self.congress_names
    require 'fastercsv'
    names = generate_congress_names
    string = FasterCSV.generate do |csv|
      csv << ["district", "name"]
      names.each do |district, name|
        csv << [district, name]
      end
    end
    send_data(string, :type => 'text/csv; charset=utf-8; header=present', :filename => "image_info.csv") 
  end

  def self.generate_congress_names
    require 'open-uri'
    districts = Event.find(:all).collect {|e| e.district}.uniq
    states = Event.find(:all).collect {|e| e.state}.compact.uniq.select do |state|
      DaysOfAction::Geo::STATE_CENTERS.keys.reject {|c| :DC == c}.map{|c| c.to_s}.include?(state)
    end
    results = {}
    districts.each do |district|      
      data = XmlSimple.xml_in(open("http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict&district=#{district}&district_type=FH"))
      if data['legislator'].nil?
        results[district] = "no legislator"
      elsif data['legislator'][0]['display_name'].nil?
        results[district] = "no display name"
      else
        results[district] = data['legislator'][0]['display_name'][0]
      end
    end
    states.each do |state|      
      data = XmlSimple.xml_in(open("http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict&district=#{state}1&district_type=FS"))
      results["#{state}S1"] = data['legislator'][0]['display_name'][0]

      data = XmlSimple.xml_in(open("http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict&district=#{state}2&district_type=FS"))
      results["#{state}S2"] = data['legislator'][0]['display_name'][0]
    end    
    return results
  end

  def self.collect_featured_images
    events = Event.find(:all, :include => :reports)
    events.reject! {|e| e.reports.empty?}
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
    render :inline => "generated zip successfully, please download it <%= link_to 'here', '/featured_images.zip' %>"
  end

  def self.featured_images 
    collect_featured_images
    image_names = @featured_images.collect {|a| File.expand_path(a.full_filename)}.join(' ')
    result = `zip #{File.join(RAILS_ROOT,'public','featured_images.zip')} #{image_names}`
    render :inline => "generated zip successfully, please download it <%= link_to 'here', '/featured_images.zip' %>"
#    send_data result, :filename => 'featured_images.zip'
  end

  def self.featured_images_print
    collect_featured_images
    image_names = @featured_images.collect {|a| a.full_filename(:print)}.join(' ')
    result = `zip #{File.join(RAILS_ROOT,'public','featured_images_print.zip')} #{image_names}`
    render :inline => "generated zip successfully, please download it <%= link_to 'here', '/featured_images_print.zip' %>"
  end

  def self.image_info
    require 'fastercsv'
    events = Event.find(:all, :include => :reports)
    events.reject! {|e| e.reports.empty?}
    democracy_in_action_events = DemocracyInActionEvent.find(events.collect {|e| e.service_foreign_key}.select {|e| !e.blank?})
    democracy_in_action_events = democracy_in_action_events.index_by {|e| e.key}

    string = FasterCSV.generate do |csv|
      csv << ["event_id", "event_name", "city", "state", "district", "host_id", "image_name"]
      events.each do |e|
        attachments = e.reports.collect {|r| r.attachments}.flatten.sort_by {|a| a.primary ? 1 : 0}
        next if attachments.empty?
        primary = attachments.first if attachments.first.primary
        primary ||= e.reports.first.attachments.first
        primary ||= attachments.first
        csv << [e.id, e.name, e.city, e.state, e.district, democracy_in_action_events[e.service_foreign_key].supporter_KEY, primary.filename]
      end
    end
    send_data(string, :type => 'text/csv; charset=utf-8; header=present', :filename => "image_info.csv")
  end

  def self.attendance
    require 'fastercsv'
    events = Event.find(:all, :include => :reports)
    string = FasterCSV.generate do |csv|
      csv << ["event_id","name","city","state","min","max","average"]
      events.each do |e|
        attendees = e.reports.collect {|r| r.attendees}.reject {|a| 0 == a }.compact
        sum = attendees.inject {|sum, n| sum + n}
        avg = sum ? sum / attendees.length : nil
        csv << [e.id, e.name, e.city, e.state, attendees.min, attendees.max, avg]
      end
    end
    send_data(string, :type => 'text/csv; charset=utf-8; header=present', :filename => "attendance.csv")
  end

  def self.host_info
    require 'fastercsv'
    democracy_in_action_events = DemocracyInActionEvent.find(:all)
    democracy_in_action_hosts = DemocracyInActionSupporter.find(democracy_in_action_events.collect {|e| e.supporter_KEY}.reject {|key| key.blank?})

    democracy_in_action_hosts = democracy_in_action_hosts.index_by {|s| s.key}

    string = FasterCSV.generate do |csv|
      csv << ["host_key", "democracy_in_action_event_key", "event_id", "first_name", "last_name", "salutation", "address", "city", "state", "zip"]
      democracy_in_action_events.each do |event|
        host = democracy_in_action_hosts[event.supporter_KEY]
        next unless host
        e = Event.find_by_service_foreign_key(event.key)
        event_id = e ? e.id : nil
        csv << [host.key, event.key, event_id, host.First_Name, host.Last_Name, host.Title, [host.Street, host.Street_2].compact.join("\n"), host.City, host.State, host.Zip]
      end
    end
    send_data(string, :type => 'text/csv; charset=utf-8; header=present', :filename => "host_info.csv")
  end

  def self.all_images
    @attachments = Report.published.find(:all, :include => :attachments).collect {|r| r.attachments}.flatten
    render :inline => "<%= Digest::MD5.hexdigest(@attachments.collect {|a| a.full_filename}.sort.join(' ')) %>"
#    send_data `zip -j - #{attachments.collect {|a| a.full_filename}.join(' ')}`, :filename => 'all_images.zip'
  end

  def self.write_update_migration
    return false
    events = Event.find(:all, :conditions => "district IS NOT NULL AND person_legislator_ids IS NOT NULL")
    File.open(File.join(RAILS_ROOT,'db','migrate','districts_and_legislators.sql'), 'w') do |file|
      events.each do |event|
        file << "UPDATE events SET `district` = '#{event.district}', `person_legislator_ids` = '#{event.person_legislator_ids}' WHERE `service_foreign_key` = '#{event.description}';\n"
      end
    end
    render :text => 'success'
  end

  def self.update_campaigns
    campaign = DemocracyInActionCampaign.find(7199)

    events = Event.find(:all, :conditions => "district IS NOT NULL AND person_legislator_ids IS NOT NULL AND campaign_key IS NULL")

    html = ""
    events.each do |event|
      @event = event
      new_campaign = campaign.clone
      new_campaign.key = nil
      new_campaign.campaign_KEY = nil

      new_campaign.Suggested_Subject = render_to_string(:template => "reports/action/subject", :layout => false)
      new_campaign.person_legislator_IDS = @event.person_legislator_ids
      new_campaign.Suggested_Content = render_to_string(:template => "reports/action/action", :layout => false)
      new_campaign.Spread_The_Word_Text = render_to_string(:template => "reports/action/spread_word", :layout => false)
      new_campaign.Reference_Name = "#{@event.service_foreign_key}: #{@event.city}, #{@event.state}"
    
      new_campaign.save
      @event.update_attribute(:campaign_key, new_campaign.key)
      html << "added campaign: #{new_campaign.key}<br/>"
    end
    render :text => html, :layout => false
  end

  def self.update_districts
    events = Event.find(:all, :conditions => {:district => nil, :person_legislator_ids => nil})

    api = DIA_API_Simple.new "authCodes" => ["jwarnow@gmail.com", "80by50", 1879]
    remote_events = api.get 'event', 'column' => 'supporter_KEY,Zip,State', 'key' => events.collect {|e| e.democracy_in_action_key}.compact
    hosts = api.get 'supporter', 'key' => remote_events.collect {|e| e['supporter_KEY']}, 'column' => 'District'

    html = ""
    require 'open-uri'
    remote_events.each do |event|
      
      host = hosts.detect {|h| h['supporter_KEY'] == event['supporter_KEY']}
      html << "no host for event #{event['event_KEY']}/n" and next unless host

      district = nil
      if host['District'] && host['District'] != 'N/A'
        district = host['District'].strip
      else
        html << "no zip for event #{event['event_KEY']}/n" and next unless event['Zip']
        begin
          xml = open("http://warehouse.democracyinaction.org/dia/api/warehouse/append.jsp?id=radicaldesigns&postal_code=#{event['Zip']}")
          if xml.is_a?(Tempfile)
            xml = xml.read
          end
          data = XmlSimple.xml_in(xml)
          next if data.empty?
        rescue 
          html << "got an error trying to open warehouse with zip: #{event['Zip']}/n"
          next
        end
        district = data['entry'][0]['district'][0].strip if data['entry'][0]['district']
      end
      html << "no district for event #{event['event_KEY']}!/n" and next unless district

      congress = []

      data = XmlSimple.xml_in(open("http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict&district=#{district}&district_type=FH"))
      html << "error for event #{event['event_KEY']}: #{data['error'][0]}/n" and next if data['error']
      congress << data['legislator'][0]['person_legislator_ID'][0]

      data = XmlSimple.xml_in(open("http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict&district=#{event['State']}1&district_type=FS"))
      html << "error for event #{event['event_KEY']}: #{data['error'][0]}/n" and next if data['error']
      congress << data['legislator'][0]['person_legislator_ID'][0] unless data.blank?

      data = XmlSimple.xml_in(open("http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict&district=#{event['State']}2&district_type=FS"))
      html << "error for event #{event['event_KEY']}: #{data['error'][0]}/n" and next if data['error']
      congress << data['legislator'][0]['person_legislator_ID'][0] unless data.blank?

      e = events.detect {|local_event| event['event_KEY'] == local_event.democracy_in_action_key}
      e.district = district
      e.person_legislator_ids = congress.compact.join(',')
      e.perform_remote_update = false
      e.save_with_validation(false)
      html << "updating event with DIA key #{event['event_KEY']} with:<br/>district: '#{district}'<br/>person_legislator_ids: '#{congress.compact.join(',')}'/n"
    end

    return html
#      render :text => html
  end

  def self.generate_map
    require 'RMagick'
    image = Magick::Image.read(File.join(RAILS_ROOT,'lib','fresh.png')).first
    width = image.columns
    height = image.rows
    gc = Magick::Draw.new
    gc.fill "#75AD50"
    events = Event.find(:all)
    coords = events.collect {|e| e.national_map_coordinates}.select do |c|
      c && c[0].nonzero? && c[1].nonzero? &&
        (24.520833..49.384472).include?(c[0]) &&
        (-124.736611..-66.950556).include?(c[1])
    end
    gxf = 8.9
    gyf = 11.55
    gxs = 56.4
    gys = 23.9
    coords.each do |c|
      y     = (height - (-gys + c[0]) * gyf).round
      rat   = (height - y) / height
      gxfa  = gxf - (rat * 1.13)
      gxsa  = gxs - (rat * 5.77)
      x     = (width + ((gxsa + c[1])*gxfa)).round
      gc.circle x+5, y-5, x+10, y-5
    end
    gc.draw image
    send_data image.to_blob, :type => image.mime_type, :disposition => 'inline'
  end

  def self.load_data
    case params[:id]
    when 'test'
      require 'active_record/fixtures'
      ['calendars.yml', 'events.yml', 'reports.yml'].each do |fixture_file| 
        Fixtures.create_fixtures(File.join('test','fixtures'), File.basename(fixture_file, '.*'))
      end
      flash[:notice] = "Test fixtures loaded"
    when 'dia'
      result = Calendar.load_from_dia(1, :host => request.env["HTTP_HOST"])
      flash[:notice] = "#{result.imported} events imported, #{result.imported - result.unknown - result.inaccurate} geocoded; of the rest, #{result.unknown} google could not geocode, #{result.inaccurate} geocoded with too low a degree of accuracy"
      expire_page_caches
    end
    redirect_to '/admin/events'
  end




#class AttachmentsController < ApplicationController
  def self.demo_stamped
    html=<<HTML
    <div style="padding: 10 10 10 10; background-color: 395875;">
    <h3>normal</h3>
    <%= image_tag @attachment.public_filename %><br/>
    <h3>stamped</h3>
    <%= image_tag url_for(:controller => :attachments, :action => :stamped, :id => @attachment) %>
    </div>
HTML
    @attachment = Attachment.find(params[:id])
    render :inline => html, :layout => true
  end

  def self.stamped
    require 'RMagick'

    @attachment = Attachment.find(params[:id])
    image = Magick::Image.read(@attachment.full_filename).first

    canvas = Magick::Image.new(image.columns, image.rows + 20) {|c| c.format = image.format}
    canvas.composite! image, Magick::NorthGravity, Magick::OverCompositeOp

    text = Magick::Draw.new
    text.annotate(canvas, 0, 0, 10, canvas.rows - 10, "Image from event #{@attachment.report.event.id} in #{@attachment.report.event.city}, #{@attachment.report.event.state}") { |t|
      t.font_weight = Magick::BoldWeight
    }
    send_data canvas.to_blob, :type => canvas.mime_type, :disposition => 'inline'
  end

=begin
  # from pull_legislators.rb
  require 'open-uri'

  def get_phone
    Politician.find(:all).each do |p|
      data = XmlSimple.xml_in(p.xml)
      p.phone = data['legislator'][0]['phone'][0]
      p.save
    end
  end

  def pull_legislators
    dia_warehouse_uri = "http://warehouse.democracyinaction.org/dia/api/warehouse/legislator.jsp?method=getLegislatorFromDistrict".freeze
    states = DemocracyInAction::Helpers.state_options_for_select.collect {|s| s[1]}
  
    states.each do |state|
      next if ((state == "none") || (state == "ot"))
      # 55 reps in calif, do 60 just to be safe
      60.times do |district|
        uri = sprintf("%s%s%s%02d%s", dia_warehouse_uri, "&district=", state, (district+1), "&district_type=FH")
        puts uri.to_s
        xml_io = open(uri)
        data = XmlSimple.xml_in(xml_io)
        break if data['legislator'].nil?
        xml_io.rewind
        xml_as_text = xml_io.read
        xml_to_legislator(data, xml_as_text) 
      end
  
      # pull data for 2 senators per state
      2.times do |senator|
        uri = dia_warehouse_uri + "&district=#{state}#{senator+1}&district_type=FS"
        puts uri.to_s
        xml_io = open(uri)
        data = XmlSimple.xml_in(xml_io)
        break if data['legislator'].nil?
        xml_io.rewind
        xml_as_text = xml_io.read
        xml_to_legislator(data, xml_as_text) 
      end
    end
  end

  def xml_to_legislator(data, xml_as_text)
    unless data['legislator'].nil?
      d = data['legislator'][0]
      l = Politician.new
      l.display_name = d['display_name'][0] unless d['display_name'][0][0].nil?
      l.first_name = d['given_name'][0] unless d['given_name'][0][0].nil?
      l.last_name = d['family_name'][0] unless d['family_name'][0][0].nil?
      l.person_legislator_id = d['person_legislator_ID'][0] unless d['person_legislator_ID'][0][0].nil?
      l.phone = d['preferred_phone'][0] unless d['preferred_phone'][0][0].nil?
      l.email = d['email'][0] unless d['email'][0][0].nil?
      l.address = d['address_line'][0] unless d['address_line'][0][0].nil?
      l.address = l.address.to_s + d['address_line_2'][0].to_s unless d['address_line_2'][0][0].nil?
      # city not returned by dia l.city] = d[''][0] 
      l.state = d['region'][0] unless d['region'][0][0].nil?
      l.postal_code= d['postal_code'][0] unless d['postal_code'][0][0].nil?
      l.district = d['district_code'][0] unless d['district_code'][0][0].nil?
      l.district_type = d['district_type'][0] unless d['district_type'][0][0].nil?
      unless d['official_ID'][0][0].nil?
        congress_uri = "http://bioguide.congress.gov/bioguide/photo/"
        id = d['official_ID'][0]
        l.image_url = congress_uri + id.first + "/" + id + ".jpg"
      end
      l.party = d['party'][0] unless d['party'][0][0].nil?
      l.website = d['website'][0] unless d['website'][0][0].nil?
      l.xml = xml_as_text
      puts "#{l.display_name}"
      l.save
    end
  end
=end

=begin
  # from db/redirect_path.rb
  objects = DemocracyInActionObject.find(:all, :conditions => "democracy_in_action_tables.table = 'campaign'")
  objects.each do |o|
  	c = o.local
  	e = o.associated
  	if c.person_legislator_IDS
  	  p = Politician.find_by_person_legislator_id(c.person_legislator_IDS)
  	else
  	  p = Politician.find(:first, :include => :democracy_in_action_object,
  	      :conditions => "democracy_in_action_objects.key = #{c.recipient_KEYS}")
  	end
  	c.redirect_path = "http://events.stepitup2007.org/november/events/#{e.id}/invite/thank_you/#{p.id}"
  	c.save
  end
=edn

end
