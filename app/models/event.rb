class Event < ActiveRecord::Base
  COUNTRY_CODE_USA = CountryCodes.find_by_name("United States of America")[:numeric] 
  COUNTRY_CODE_CANADA = CountryCodes.find_by_name("Canada")[:numeric] 

  belongs_to :calendar
  belongs_to :host, :class_name => 'User', :foreign_key => 'host_id'
  has_many :reports, :conditions => "reports.status = '#{Report::PUBLISHED}'", :include => :attachments, :order => 'reports.position', :dependent => :destroy do
    def slideshow?
      Site.current.flickr_user_id && proxy_target.collect {|r| r.attachments}.flatten.any?
    end    
    def attachments
      proxy_target.collect {|r| r.attachments}.flatten
    end
  end
  has_many :attachments, :dependent => :destroy
  has_many :documents, :class_name => 'Attachment', :conditions => Attachment.types_to_conditions([:document])
  has_many :images, :class_name => 'Attachment', :conditions => Attachment.types_to_conditions([:image])
  has_many :press_links, :through => :reports
  has_many :rsvps, :dependent => :destroy
  has_many :attendees, :through => :rsvps, :source => :user
  has_finder :searchable, :conditions => ["private = ? OR private IS NULL", false]
  has_finder :mappable, :conditions => ["(latitude <> 0 AND longitude <> 0) AND (state IS NOT NULL AND state <> '') AND country_code = ?", COUNTRY_CODE_USA]
  has_finder :private, :conditions => "private = 1"
  has_finder :with_reports, :include => :reports, :conditions => ["reports.status = ?", Report::PUBLISHED]

  belongs_to :category

  acts_as_mappable :lat_column_name => 'latitude', :lng_column_name => 'longitude'
  before_validation :geocode
  before_save :set_calendar, :set_district, :clean_country_state, :clean_date_time
  
  validates_presence_of :name, :city, :start, :calendar_id, :country_code

  def find_by_calendar_id( calendar_id )
  end

  has_finder :first_category, lambda { |category_id|
    { :order => "if( category_id = #{category_id.to_i}, 1, 0) DESC" }
  }

  has_finder :all, lambda { { }}
  has_finder :first, lambda { { :limit => 1 }}

  has_finder :upcoming, lambda {{:conditions => ["end >= ?", Time.now], :order => 'start, state'}}
  has_finder :past, lambda {{:conditions => ["end <= ?", Time.now], :order => 'start DESC, state'}}

  def self.with_upcoming
    with_scope(:find => {:conditions => ["end >= ?", Time.now]}) do
      yield
    end
  end
  def self.with_past
    with_scope(:find => {:conditions => ["end <= ?", Time.now]}) do
      yield
    end
  end

  has_finder :created_at, lambda { |order|
    { :order => "created_at #{order =~ /desc/i ? 'DESC' : 'ASC'}" }
  }

  # finder-chainer!!!
  def self.prioritize(sort)
    return self.all if sort.nil?
    sort.inject(self.all) { |search, (finder, value) | sorted = search.send( finder.to_sym, value ) if finders[ finder.to_sym ]; sorted || search }
  end

  has_finder :by_query, lambda {|query| 
    if query && !query.empty?
      Event.verify_calendar_id( query )
      {:conditions => query }
    else
      {}
    end
  }

  def self.verify_calendar_id(query)
    return query unless permalink = query.delete(:permalink) || calendar_id = query.delete(:calendar_id)
    if permalink 
      calendar_id ||= Site.current.calendars.inject(nil) { |memo, c| memo ||= ( c.permalink == permalink ? c.id : memo ) }
    end
    query[:calendar_id] = Calendar.find(calendar_id).calendar_ids + [ calendar_id ]
  end

  def state_is_canadian_province?
      usa_valid_states = DemocracyInAction::Helpers.state_options_for_select.map{|a| a[1]}
      all_valid_states = DemocracyInAction::Helpers.state_options_for_select(:include_provinces => true).map{|a| a[1]}
      valid_provinces = all_valid_states - usa_valid_states
      not state.blank? and valid_provinces.include?(state)
  end

  def clean_date_time
    self.end ||= self.start + 4.hours
  end
  
  def clean_country_state
    # usa is default country, if user sets state to 
    # canadian province, set country to canada
    if in_usa? and state_is_canadian_province? 
      country_code = COUNTRY_CODE_CANADA 
    end
    unless in_usa? or in_canada?
      state = nil 
    end
  end

  def validate
    validate_postal_code
    validate_state
    validate_dates
    validates_mappable
  end
  
  def validate_postal_code
    if in_usa?
      unless postal_code =~ /^\d{5}(-\d{4})?$/
        errors.add :postal_code, "is not a valid U.S. postal code"
      end
    elsif in_canada?
      unless postal_code =~ /^\D\d\D((-| )?\d\D\d)?$/
        errors.add :postal_code, "is not a valid Canadian postal code"
      end
    end      
  end

  def validate_state
    if in_usa?
      valid_us_states = DemocracyInAction::Helpers.state_options_for_select.map{|a| a[1]}
      if state.blank? or not valid_us_states.include?(state)
        errors.add :state, "is not a valid U.S. state"
      end      
    elsif in_canada?
      unless state_is_canadian_province?
        errors.add :state, "is not a valid Canadian province"
      end
    end
  end

  def validate_dates
    if (self.start && self.end) && (self.start > self.end)
      errors.add :start, "date must be before end date"
    end
    if (self.start && calendar.event_start) && (self.start < calendar.event_start.at_beginning_of_day)
      message = (calendar.event_end && (calendar.event_start.to_date == calendar.event_end.to_date)) ? "on" : "on or after"
      errors.add :start, "must be #{message} #{calendar.event_start.strftime('%B %e, %Y')}"
    end
    if (self.end && calendar.event_end) && (self.end > (calendar.event_end + 1.day).at_beginning_of_day)
      message = (calendar.event_start.to_date == calendar.event_end.to_date) ? "on" : "on or before"
      errors.add :end, "must be #{message} #{calendar.event_end.strftime('%B %e, %Y')}"
    end
  end
  
  def validates_mappable
    # only check that usa and canadian events are mappable
    if (in_usa? || in_canada?) && !(self.latitude && self.longitude)
      errors.add_to_base "Not enough information provided to place event on a map. Please give us at minimum a valid postal code."
    end
  end

  has_many :blogs  

  has_one :democracy_in_action_object, :as => :synced
  def democracy_in_action_synced_table
    'event'
  end

  attr_writer :democracy_in_action
  after_save :sync_to_democracy_in_action
  def sync_to_democracy_in_action
    return unless File.exists?(File.join(Site.current_config_path, 'democracyinaction-config.yml'))
    @democracy_in_action ||= {}
    extra = @democracy_in_action[:event] || {}
    event = self.to_democracy_in_action_event
    extra.each do |key, value|
      event.send "#{key}=", value
    end
    key = event.save
    self.create_democracy_in_action_object :key => key, :table => 'event' unless self.democracy_in_action_object
  end

  has_one :salesforce_object, :as => :mirrored, :class_name => 'ServiceObject', :dependent => :destroy
  after_save :sync_to_salesforce
  def sync_to_salesforce
    return true unless Site.current.salesforce_enabled?
    SalesforceWorker.async_save_event(:event_id => self.id) 
  rescue Workling::WorklingError => e
    logger.error("SalesforceWorker.async_save_event(:event_id => #{self.id}) failed! Perhaps workling is not running. Got Exception: #{e}")
    return true # don't kill the callback chain since it may still do something useful
  end

  before_destroy :delete_from_salesforce
  def delete_from_salesforce
    return true unless Site.current.salesforce_enabled? && self.salesforce_object
    SalesforceWorker.async_delete_event(self.salesforce_object.remote_id) 
  rescue Workling::WorklingError => e
    logger.error("SalesforceWorker.async_delete_event(:event_id => #{self.id}) failed! Perhaps workling is not running. Got Exception: #{e}")
    return true # don't kill the callback chain since it may still do something useful
  end

  after_create :trigger_email
  def trigger_email
    c = self.calendar
    unless c.hostform and c.hostform.dia_trigger_key
      trigger =    c.triggers.find_by_name("Host Thank You") || 
        Site.current.triggers.find_by_name("Host Thank You")
      TriggerMailer.deliver_trigger(trigger, self.host, self) if trigger
    end
  end

  def trigger_email
    calendar = self.calendar
    unless calendar.hostform and calendar.hostform.dia_trigger_key
      if calendar.triggers
        trigger = calendar.triggers.find_by_name("Host Thank You") 
      elsif Site.current.triggers
        trigger = Site.current.triggers.find_by_name("Host Thank You")
      end
      TriggerMailer.deliver_trigger(trigger, self.host, self) if trigger
    end
  end
  
  before_destroy :delete_from_democracy_in_action
  def delete_from_democracy_in_action
    o = democracy_in_action_object
    return true unless o
    api = DemocracyInAction::API.new(DemocracyInAction::Config.new(File.join(Site.current_config_path, 'democracyinaction-config.yml')))
    api.delete 'event', 'key' => self.democracy_in_action_key
    o.destroy
  end

  def to_democracy_in_action_event
    DemocracyInActionEvent.new do |e|
      e.Event_Name  = name
      e.Description = description
      e.Address     = location
      e.City        = city
      e.State       = state
      e.Zip         = postal_code
      e.Start       = "#{self.start.to_s(:db)}.0"
      e.End         = "#{self.end.to_s(:db)}.0"
      e.key         = democracy_in_action_key
      e.event_KEY   = democracy_in_action_key
      e.Latitude    = latitude
      e.Longitude   = longitude
      e.Directions  = directions
      e.supporter_KEY = (self.host ? self.host.democracy_in_action_key : '')
      e.distributed_event_KEY = self.calendar.democracy_in_action_key
    end
  end
  
  def democracy_in_action_key
    democracy_in_action_object.key if democracy_in_action_object
  end

  def address_for_geocode
    [location, city, state, postal_code].compact.join(', ').gsub /\n/, ' '
  end
  alias address address_for_geocode
  
  def start_date
    self.start.strftime("%B %d, %Y")
  end
  
  def segmented_date
    Hash[*([ :month, :day, :year, :month_name ].zip(self.start.strftime("%m %d %Y %B").split)).flatten]
  end
  
  def start_time
    self.start.strftime("%I:%M%p").downcase
  end
  
  def nearby_events
    self.calendar.events.searchable.find(:all, :origin => self, :within => 50, :conditions => ["events.id <> ?", self.id])
  end

  def set_calendar
    if self.calendar and self.calendar.calendars.any?
      self.calendar_id = (calendar.calendars.detect {|c| c.current? } || calendar.calendars.first).id
    end
  end

  # Move this to a library or DIA module or something
  require 'hpricot'
  def self.postal_code_to_district(postal_code)
    Cache.get "district_for_postal_code_#{postal_code}" do
      # get congressional district based on postal code
      dia_warehouse = "http://warehouse.democracyinaction.org/dia/api/warehouse/append.jsp?id=radicaldesigns".freeze
      uri = dia_warehouse + "&postal_code=" + postal_code.to_s
      data = Hpricot::XML(Kernel.open(uri))
      (data/:district).first.innerHTML if (data/:district) && !(data/:district).empty?
    end
  end

  def set_district
    # don't lookup U.S. congressional district for non-us postal_codes
    return unless (self.country_code == COUNTRY_CODE_USA && 
                   self.postal_code =~ /^\d{5}(-\d{4})?$/)
    self.district = Event.postal_code_to_district(self.postal_code)
  end

  def national_map_coordinates
    @zip ||= ZipCode.find_by_zip(postal_code)
    if @zip
      [@zip.latitude, @zip.longitude]
    elsif latitude && longitude
      [latitude, longitude]
    else
      false
    end
  end

  def contact_phone
    if host? && host.phone?
      return host.phone
    else
      return ''
    end
  end

  def reports_disabled
    !reports_enabled?
  end
  alias :reports_disabled? :reports_disabled

  def reports_disabled=(value)
    inverted_value = value.respond_to?( :to_i ) ? value.to_i.zero? : !value
    self.reports_enabled = inverted_value
  end

  def reportable?
    reports_enabled? && !calendar.archived?
  end

  has_finder :reportable, :include => :calendar, :conditions => ["reports_enabled = ? AND calendars.archived = ?", true, false]

  def past?
    end_datetime = self.end || self.start
    end_datetime && (end_datetime < Time.now)
  end
  
  def in_usa?
    country_code == COUNTRY_CODE_USA
  end

  def in_canada?
    country_code == COUNTRY_CODE_CANADA
  end

  def country
    CountryCodes.find_by_numeric(self.country_code)[:name]
  end

  def city_state
    [city, (state.blank? ? country : state)].join(', ')
  end
  
  def country=(name)
    self.country_code = CountryCodes.find_by_name(name)[:numeric]
  end

  def attendees_high
    rprts = reports.reject{|r| not r.attendees or r.attendees <= 0}
    return nil if rprts.empty?
    rprts.map{|r| r.attendees}.max
  end
  
  def attendees_low
    rprts = reports.reject{|r| not r.attendees or r.attendees <= 0}
    return nil if rprts.empty?
    rprts.map{|r| r.attendees}.min
  end
  
  def attendees_average
    rprts = reports.reject{|r| not r.attendees or r.attendees <= 0}
    return nil if rprts.empty?
    rprts.map{|r| r.attendees}.sum / rprts.length
  end

  def duration_in_minutes
    ((self.end - self.start) / 60).to_i
  end
  
  # render letter/call scripts that can come from event model (scripts will 
  # have been created by host) or calendar (scripts will have been created 
  # by admin).  event (host) scripts over-ride calendar (admin) scripts
  def render_scripts
    city_state = [self.city, self.state].join(', ')
    self.letter_script ||= self.calendar.letter_script.gsub('CITY_STATE', city_state) if self.calendar.letter_script
    self.call_script ||= self.calendar.call_script.gsub('CITY_STATE', city_state) if self.calendar.call_script
  end
  
private
  def geocode
    # only geocode US or Canadian events
    return unless (country_code == COUNTRY_CODE_USA or country_code == COUNTRY_CODE_CANADA)
    if (geo = GeoKit::Geocoders::MultiGeocoder.geocode(address_for_geocode)).success
      self.latitude, self.longitude = geo.lat, geo.lng
      self.precision = geo.precision
    elsif self.postal_code =~ /^\d{5}(-\d{4})?$/ and (zip = ZipCode.find_by_zip(self.postal_code))
      self.latitude, self.longitude = zip.latitude, zip.longitude if zip
      self.precision = 'zip'
    elsif self.postal_code   # handle US postal codes not in ZipCode table and Canadian postal
      if (geo = GeoKit::Geocoders::MultiGeocoder.geocode(self.postal_code)).success
        self.latitude, self.longitude = geo.lat, geo.lng
        self.precision = geo.precision
      end
    end
  end

end
