class Calendar < ActiveRecord::Base
  validates_uniqueness_of :permalink, :scope => :site_id
  validates_presence_of :site_id, :permalink, :name
  before_validation :escape_permalink
  before_create :attach_to_all_calendar

  def escape_permalink
    self.permalink = PermalinkFu.escape(self.permalink)
  end
  belongs_to :site

  # self-referential calendar relationship used for 'all' calendar
  belongs_to :parent, :class_name => 'Calendar', :foreign_key => 'parent_id'
  has_many :calendars, :class_name => 'Calendar', :foreign_key => 'parent_id'
#    def current
#      proxy_target.detect {|c| c.current?} || proxy_target.first
#    end
  has_finder :current, :conditions => {:current => true}

  @@deleted_events = []
  @@all_events = []

  has_many :events do
    def construct_sql 
      result = super
      @counter_sql = @finder_sql = "events.calendar_id IN (#{((proxy_owner.calendar_ids || []) << proxy_owner.id).join(',')})"
      result
    end
    def unique_states
      states = proxy_target.collect {|e| e.state}.compact.uniq.select do |state|
        DaysOfAction::Geo::STATE_CENTERS.keys.reject {|c| :DC == c}.map{|c| c.to_s}.include?(state)
      end
      states.length
    end
    def find_updated_since( time )
      find :all, :include => [ :host, { :reports => :user }, :attendees ], :conditions => [ "events.updated_at > :time OR users.updated_at > :time OR reports.updated_at > :time", { :time => time } ]
    end

    def prioritize( sort )
      Event.prioritize(sort).by_query( :calendar_id => proxy_owner.id )
    end
  end

  has_many :reports, :through => :events do
    def construct_conditions
      table_name = @reflection.through_reflection.table_name
      conditions = [ "events.calendar_id IN (#{((proxy_owner.calendar_ids || []) << proxy_owner.id).join(',')})" ]
      conditions << sql_conditions if sql_conditions
      final_conditions = "(" + conditions.join(') AND (') + ")"
      final_conditions
    end
  end

  def self.any?
    self.count != 0
  end
  
  def past?
    self.event_end && (self.event_end + 1.day).at_beginning_of_day < Time.now
  end

  def flickr_tags(event_id = nil)
    tags = []
    if flickr_tag
      tags << flickr_tag.to_s
      tags << (flickr_tag.to_s + event_id.to_s) if event_id
      tags << flickr_additional_tags.split(',') if flickr_additional_tags
      tags.flatten
    end
    tags
  end
  
  #XXX
  has_one :democracy_in_action_object, :as => :synced
  def democracy_in_action_synced_table
    'distributed_event'
  end
  
  def democracy_in_action_key
    democracy_in_action_object.key if democracy_in_action_object
  end
  
  def democracy_in_action_key=(key)
    return if key.blank?
    obj = self.democracy_in_action_object || self.build_democracy_in_action_object(:table => 'distributed_event')
    obj.key = key 
    obj.save
  end

  has_many :triggers
  has_many :categories
  has_one :hostform

  def self.clear_deleted_events
    raise 'method deprecated, use DemocracyInAction::Util.clear_deleted_events'
  end

  def self.load_from_dia(id, *args)
    raise 'method deprecated, use DemocracyInAction::Util.load_from_dia'
  end

  def attach_to_all_calendar
    return if self.permalink == 'all'
    all_cal = site.calendars.find_by_permalink('all')
    return unless all_cal
    self.parent_id = all_cal.id
  end

end

