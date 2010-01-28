require 'digest/sha1'
require 'ostruct'
class User < ActiveRecord::Base
  attr_protected :password, :password_confirmation

  has_many :events, :foreign_key => 'host_id'
  has_many :calendars
  has_many :reports
  has_many :rsvps
  has_many :attending, :through => :rsvps, :source => :event
  has_many :custom_attributes

  belongs_to :profile_image, :class_name => 'Attachment', :foreign_key => 'profile_image_id'
  belongs_to :site
  before_create :set_site_id
  def set_site_id
    self.site_id ||= Site.current.id if Site.current
  end
  
  def admin?
    admin || superuser?
  end

  def superuser?
    self.class.superuser_emails.include?(email)
  end

  def self.superuser_emails
    superusers_file = File.join('config', 'superusers.yml')
    return [] unless File.exist?(superusers_file)
    YAML.load_file(superusers_file)
  end

  def deferred?
    @deferred
  end
  attr_accessor :deferred

  has_one :salesforce_object, :as => :mirrored, :class_name => 'ServiceObject', :dependent => :destroy
  after_save :sync_to_salesforce
  def sync_to_salesforce
    return true unless Site.current.salesforce_enabled?
    SalesforceWorker.async_save_contact(:user_id => self.id) 
  rescue Workling::WorklingError => e
    logger.error("SalesforceWorker.async_save_contact(:user_id => #{self.id}) failed! Perhaps workling is not running. Got Exception: #{e}")
  ensure
    return true # don't kill the callback chain since it may still do something useful
  end

  before_destroy :delete_from_salesforce
  def delete_from_salesforce
    return true unless self.site.salesforce_enabled? && self.salesforce_object
    SalesforceWorker.async_delete_contact(self.salesforce_object.remote_id) #:contact_id => self.salesforce_object.remote_id) 
  rescue Workling::WorklingError => e
    logger.error("SalesforceWorker.async_delete_contact(:contact_id => #{self.salesforce_object.remote_id}) failed! Perhaps workling is not running. Got Exception: #{e}")
  ensure
    return true # don't kill the callback chain since it may still do something useful
  end

  has_one :democracy_in_action_object, :as => :synced
  # (extract me) to the plugin!!!
  # acts_as_mirrored? acts_as_synced?
  attr_accessor :democracy_in_action
  after_save :sync_to_democracy_in_action
  def sync_to_democracy_in_action
    return true unless File.exists?(File.join(Site.current_config_path, 'democracyinaction-config.yml'))
    return true if deferred? #will be handled by background process

    @democracy_in_action ||= {}
#    $DEBUG = true
    @democracy_in_action_attrs = {} #attributes to be sent across the wire
    attributes.each do |k,v|
      @democracy_in_action_attrs[k.titleize.gsub(' ', '_')] = v
    end
    @democracy_in_action_attrs['Zip'] = self.postal_code

    # probably makes more sense to use an object wrapper so it can handle supporter_custom and whatnot
    # supporter = DemocracyInActionSupporter.new
    # supporter.custom << @democracy_in_action[:supporter_custom]
    # OR @democracyinaction.select {|k,v| k =~ /supporter_/}.each
    supporter = @democracy_in_action["supporter"] || @democracy_in_action[:supporter] || {}
    links = supporter.delete("link")

    require 'democracyinaction'
    api = DemocracyInAction::API.new(DemocracyInAction::Config.new(File.join(Site.current_config_path, 'democracyinaction-config.yml')))
    supporter_key = api.process 'supporter', @democracy_in_action_attrs.merge(supporter)
    create_democracy_in_action_object :key => supporter_key, :table => 'supporter' unless self.democracy_in_action_object

    supporter_custom = @democracy_in_action["supporter_custom"] || @democracy_in_action[:supporter_custom] || {}
    supporter_custom_key = api.process('supporter_custom', {'supporter_KEY' => supporter_key}.merge(supporter_custom))

    links.each do |object, key|
      object_key = api.process("supporter_#{object}", {'supporter_KEY' => supporter_key, "#{object}_KEY" => key})
    end if links

    return true
  end

  def democracy_in_action_key
    democracy_in_action_object.key if democracy_in_action_object
  end

  def self.create_from_democracy_in_action_supporter(site, supporter)
    u = User.find_or_initialize_by_site_id_and_email(site.id, supporter.Email)
    u.first_name = supporter.First_Name
    u.last_name = supporter.Last_Name
    u.phone = supporter.Phone
    u.state = supporter.State
    u.postal_code = supporter.Zip
    unless u.democracy_in_action_key
      dia_obj = DemocracyInActionObject.new(:table => 'supporter', :key => supporter.key)
      dia_obj.save
    else
      dia_obj = u.democracy_in_action_object
    end
    unless u.save
      logger.warn("Validation error(s) occurred when trying to create user from DemocracyInActionSupporter: #{u.errors.inspect}")
      u.save_with_validation(false)
    end
    dia_obj.synced = u
    dia_obj.save
    u
  end
  
  def dia_group_key=(group_key)
    self.democracy_in_action ||= {}
    self.democracy_in_action['supporter'] ||= {}
    self.democracy_in_action['supporter']['link'] ||= {}
    self.democracy_in_action['supporter']['link']['groups'] = group_key
  end

  def dia_group_key
    democracy_in_action &&
    democracy_in_action['supporter'] && 
    democracy_in_action['supporter']['link'] && 
    democracy_in_action['supporter']['link']['groups']
  end

  def dia_trigger_key=(dia_trigger_key)
    self.democracy_in_action ||= {}
    self.democracy_in_action['supporter'] ||= {}
    self.democracy_in_action['supporter']['email_trigger_KEYS'] = dia_trigger_key
  end

  def dia_trigger_key
    democracy_in_action &&
    democracy_in_action['supporter'] && 
    democracy_in_action['supporter']['email_trigger_KEYS']
  end

  # end extract me

  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email, :scope => :site_id, :case_sensitive => false
  before_save :encrypt_password
  before_create :make_activation_code
  after_save :deliver_email
  def deliver_email
    UserMailer.deliver_forgot_password(self) if self.recently_forgot_password?
    UserMailer.deliver_reset_password(self) if self.recently_reset_password?
  end

  # Authenticates a user by their email and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    # check if this is a superuser account?
    if superuser_emails.include?(email)
      u = find_by_email(email)
    end

    # check if this user is legit for this site 
    u ||= find_by_site_id_and_email(Site.current.id, email, :conditions => 'activated_at IS NOT NULL')
    u && u.authenticated?(password) ? u : nil
  end

  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end

  def reset_password
    # First update the password_reset_code before setting the 
    # reset_password flag to avoid duplicate email notifications.
    update_attributes(:password_reset_code => nil)
    @reset_password = true
  end

  def recently_reset_password?
    @reset_password
  end

  def recently_forgot_password?
    @forgotten_password
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def full_name
    [first_name, last_name].compact.join(' ')
  end
  alias :name :full_name

  def address
    [street, street_2, city, state, postal_code].compact.join(', ')
  end
  
  def attending?(event)
    self.attending.any? {|e| e.id == event.id}
    self.events.any? {|e| e.id == event.id}
  end

  # most recently hosted or attended event
  def effective_event
    (self.events + self.attending).max{|a,b| a.end <=> b.end}
  end  

  # get calendar for most recently hosted or attended event
  def effective_calendar
    effective_event ? effective_event.calendar : (Site.current.calendars.detect {|c| c.current?} || Site.current.calendars.first)
  end
  
  def country
    CountryCodes.find_by_numeric(self.country_code)[:name]
  end

  def country=(name)
    self.country_code = CountryCodes.find_by_name(name)[:numeric]
  end

  def city_state
    [city, (state || country)].join(', ')
  end
    
  before_validation :assign_password
  def assign_password
    return true if self.password || crypted_password
    randomize_password
  end

  def randomize_password
    return true if crypted_password
    self.password = self.password_confirmation = User.random_password
  end

  def self.random_password
    Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  def custom_attributes_data
    OpenStruct.new( Hash[ *custom_attributes.map { |attr| [ attr.name, attr.value ] }.flatten ] )
  end

  def custom_attributes_data=(values)
    values.each do | name, value |
      attr = custom_attributes.find_by_name( name.to_s ) || custom_attributes.build( :name => name.to_s )
      attr.value = value
    end
    
  end

  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end

    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
    def make_password_reset_code
      self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end
end
