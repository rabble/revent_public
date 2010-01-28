class Trigger < ActiveRecord::Base
	belongs_to :calendar
	belongs_to :site

  TRIGGER_NAMES = ["Host Thank You", "RSVP Thank You", "Report Thank You", "Report Host Reminder"]

	validates_presence_of     :from, :email_plain
  validates_length_of       :from, :within => 3..100
	validates_uniqueness_of   :name, :scope => [:site_id, :calendar_id]
end
