# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 94) do

  create_table "attachments", :force => true do |t|
    t.string   "content_type"
    t.string   "filename"
    t.integer  "size"
    t.integer  "parent_id"
    t.string   "thumbnail"
    t.integer  "width"
    t.integer  "height"
    t.string   "caption"
    t.string   "url"
    t.integer  "position"
    t.string   "author"
    t.string   "type"
    t.integer  "user_id"
    t.integer  "event_id"
    t.integer  "report_id"
    t.boolean  "primary",      :default => false
    t.string   "flickr_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "attachments", ["report_id"], :name => "index_attachments_on_report_id"
  add_index "attachments", ["parent_id"], :name => "index_attachments_on_parent_id"
  add_index "attachments", ["event_id"], :name => "index_attachments_on_event_id"
  add_index "attachments", ["content_type"], :name => "index_attachments_on_content_type"

  create_table "blogs", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "event_id"
  end

  add_index "blogs", ["event_id"], :name => "index_blogs_on_event_id"

  create_table "calendars", :force => true do |t|
    t.string   "name"
    t.text     "short_description"
    t.integer  "user_id"
    t.string   "permalink"
    t.integer  "site_id"
    t.boolean  "current",                 :default => false
    t.string   "theme"
    t.string   "signup_redirect"
    t.datetime "event_start"
    t.datetime "event_end"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "letter_script"
    t.text     "call_script"
    t.integer  "hostform_id"
    t.integer  "rsvp_dia_group_key"
    t.integer  "rsvp_dia_trigger_key"
    t.integer  "report_dia_group_key"
    t.integer  "report_dia_trigger_key"
    t.string   "flickr_tag"
    t.string   "flickr_additional_tags"
    t.string   "flickr_photoset"
    t.string   "rsvp_redirect"
    t.string   "report_redirect"
    t.string   "report_title_text"
    t.text     "report_intro_text"
    t.string   "attendee_invite_subject"
    t.text     "attendee_invite_message"
    t.string   "admin_email"
    t.text     "map_intro_text"
    t.integer  "parent_id"
    t.integer  "host_dia_trigger_key"
    t.integer  "host_dia_group_key"
    t.datetime "suggested_event_start"
    t.boolean  "archived",                :default => false
    t.boolean  "auto_publish_reports"
  end

  add_index "calendars", ["permalink"], :name => "index_calendars_on_permalink"
  add_index "calendars", ["site_id"], :name => "index_calendars_on_site_id"
  add_index "calendars", ["parent_id"], :name => "index_calendars_on_parent_id"

  create_table "categories", :force => true do |t|
    t.string  "name"
    t.string  "description"
    t.integer "calendar_id"
    t.integer "site_id"
  end

  add_index "categories", ["calendar_id"], :name => "index_categories_on_calendar_id"

  create_table "custom_attributes", :force => true do |t|
    t.integer "user_id"
    t.string  "name"
    t.string  "value"
  end

  add_index "custom_attributes", ["user_id"], :name => "index_custom_attributes_on_user_id"

  create_table "democracy_in_action_objects", :force => true do |t|
    t.string   "synced_type"
    t.integer  "synced_id"
    t.string   "table"
    t.integer  "key"
    t.text     "local"
    t.string   "associated_type"
    t.integer  "associated_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "democracy_in_action_objects", ["synced_id", "synced_type"], :name => "index_on_synced_id_and_synced_type"
  add_index "democracy_in_action_objects", ["associated_id", "associated_type"], :name => "index_on_associated_id_and_associated_type"
  add_index "democracy_in_action_objects", ["table", "key"], :name => "index_on_table_and_key"

  create_table "embeds", :force => true do |t|
    t.text    "html"
    t.string  "caption"
    t.integer "user_id"
    t.string  "youtube_video_id"
    t.string  "preview_url"
    t.integer "report_id"
  end

  create_table "events", :force => true do |t|
    t.string   "name"
    t.text     "short_description"
    t.text     "description"
    t.integer  "calendar_id"
    t.text     "location"
    t.string   "city"
    t.string   "state"
    t.string   "postal_code"
    t.integer  "host_id"
    t.datetime "start"
    t.datetime "end"
    t.float    "latitude"
    t.float    "longitude"
    t.text     "directions"
    t.string   "person_legislator_ids"
    t.string   "district"
    t.integer  "campaign_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "letter_script"
    t.text     "call_script"
    t.boolean  "private"
    t.integer  "max_attendees"
    t.integer  "category_id"
    t.float    "fallback_latitude"
    t.float    "fallback_longitude"
    t.string   "precision"
    t.integer  "country_code",          :default => 840
    t.string   "organization"
    t.boolean  "reports_enabled",       :default => true
  end

  add_index "events", ["latitude", "longitude"], :name => "index_events_on_latitude_and_longitude"
  add_index "events", ["postal_code"], :name => "index_events_on_postal_code"
  add_index "events", ["calendar_id"], :name => "index_events_on_calendar_id"
  add_index "events", ["state", "city"], :name => "index_events_on_state_and_city"
  add_index "events", ["host_id"], :name => "index_events_on_host_id"

  create_table "hostforms", :force => true do |t|
    t.string  "title"
    t.text    "intro_text"
    t.text    "event_info_text"
    t.text    "thank_you_text"
    t.text    "pre_submit_text"
    t.integer "trigger_id"
    t.integer "dia_trigger_key"
    t.integer "dia_group_key"
    t.string  "dia_user_tracking_code"
    t.string  "dia_event_tracking_code"
    t.string  "redirect"
    t.integer "calendar_id"
    t.integer "site_id"
  end

  add_index "hostforms", ["calendar_id"], :name => "index_hostforms_on_calendar_id"

  create_table "logged_exceptions", :force => true do |t|
    t.string   "exception_class"
    t.string   "controller_name"
    t.string   "action_name"
    t.text     "message"
    t.text     "backtrace"
    t.text     "environment"
    t.text     "request"
    t.datetime "created_at"
  end

  create_table "politician_invites", :force => true do |t|
    t.integer  "user_id"
    t.integer  "politician_id"
    t.integer  "event_id"
    t.string   "invite_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "politician_invites", ["politician_id"], :name => "index_politician_invites_on_politician_id"

  create_table "politicians", :force => true do |t|
    t.string   "title"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "district"
    t.integer  "person_legislator_id"
    t.string   "display_name"
    t.string   "phone"
    t.string   "email"
    t.string   "address"
    t.string   "state"
    t.string   "postal_code"
    t.string   "district_type"
    t.string   "image_url"
    t.string   "website"
    t.string   "party"
    t.text     "xml"
    t.string   "type"
    t.string   "office"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "city"
    t.string   "contact_state"
    t.string   "fax"
    t.string   "web_form"
    t.integer  "parent_id"
  end

  add_index "politicians", ["state"], :name => "index_politicians_on_state"
  add_index "politicians", ["district_type"], :name => "index_politicians_on_district_type"
  add_index "politicians", ["district"], :name => "index_politicians_on_district"
  add_index "politicians", ["type"], :name => "index_politicians_on_type"
  add_index "politicians", ["person_legislator_id"], :name => "index_on_person_legislator_id"

  create_table "press_links", :force => true do |t|
    t.string   "url"
    t.string   "text"
    t.integer  "report_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "press_links", ["report_id"], :name => "index_press_links_on_report_id"

  create_table "reports", :force => true do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.text     "text"
    t.integer  "position"
    t.string   "status"
    t.string   "reporter_name"
    t.string   "reporter_email"
    t.integer  "attendees"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "featured"
  end

  add_index "reports", ["event_id"], :name => "index_reports_on_event_id"
  add_index "reports", ["status", "position"], :name => "index_reports_on_status_and_position"

  create_table "rsvps", :force => true do |t|
    t.integer  "event_id"
    t.integer  "user_id"
    t.text     "comment"
    t.integer  "guests"
    t.string   "attending_type"
    t.integer  "attending_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "proxy"
  end

  add_index "rsvps", ["attending_id", "attending_type"], :name => "index_rsvps_on_attending_id_and_attending_type"
  add_index "rsvps", ["event_id"], :name => "index_rsvps_on_event_id"
  add_index "rsvps", ["user_id"], :name => "index_rsvps_on_user_id"

  create_table "service_objects", :force => true do |t|
    t.string   "mirrored_type"
    t.integer  "mirrored_id"
    t.string   "remote_service"
    t.string   "remote_type"
    t.string   "remote_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sites", :force => true do |t|
    t.string   "host"
    t.string   "theme"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "partner_redirect_url"
  end

  add_index "sites", ["host"], :name => "index_sites_on_host", :unique => true

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",        :default => 0,  :null => false
    t.integer  "taggable_id",   :default => 0,  :null => false
    t.string   "taggable_type", :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "taggings", ["tag_id", "taggable_id", "taggable_type"], :name => "index_taggings_on_tag_id_and_taggable_id_and_taggable_type", :unique => true

  create_table "tags", :force => true do |t|
    t.string   "name",       :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "triggers", :force => true do |t|
    t.string   "name"
    t.string   "from"
    t.string   "from_name"
    t.string   "reply_to"
    t.string   "subject"
    t.string   "bcc"
    t.text     "email_plain"
    t.text     "email_html"
    t.integer  "calendar_id"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",           :limit => 40
    t.string   "salt",                       :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "phone"
    t.string   "street"
    t.string   "street_2"
    t.string   "city"
    t.string   "state"
    t.string   "postal_code"
    t.string   "activation_code",            :limit => 40
    t.datetime "activated_at"
    t.string   "password_reset_code",        :limit => 40
    t.integer  "profile_image_id"
    t.boolean  "show_phone_on_host_profile"
    t.integer  "site_id"
    t.integer  "country_code"
    t.string   "partner_id"
    t.boolean  "admin"
    t.string   "organization"
  end

  add_index "users", ["email", "site_id"], :name => "unique_index_on_email_and_site_id"
  add_index "users", ["site_id"], :name => "index_users_on_site_id"

  create_table "zip_codes", :force => true do |t|
    t.string   "zip"
    t.string   "city"
    t.string   "state",      :limit => 2
    t.float    "latitude"
    t.float    "longitude"
    t.string   "zip_class"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "zip_codes", ["latitude"], :name => "index_zip_codes_on_latitude"
  add_index "zip_codes", ["longitude"], :name => "index_zip_codes_on_longitude"
  add_index "zip_codes", ["latitude", "longitude"], :name => "index_zip_codes_on_latitude_and_longitude"
  add_index "zip_codes", ["zip"], :name => "index_zip_codes_on_zip"

end
