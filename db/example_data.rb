module FixtureReplacement
  attributes_for :attachment do |a|
    a.filename = "test_file"
    a.content_type = 'image/jpeg' 
    a.size = 50
  end

  attributes_for :blog do |a|
    
	end

  attributes_for :calendar do |a|
    a.name = "Step It Up" 
    a.permalink = "stepitup"
    a.site = default_site
    a.theme = "stepitup"
    a.event_start = 5.years.ago
    a.event_end = 5.years.from_now
	end

  attributes_for :category do |a|
    
	end

  attributes_for :democracy_in_action_object do |a|
    
	end

  attributes_for :embed do |a|
    a.html = "some html"
    
	end

  cities = ["San Francisco", "New York", "Santa Fe", "Seattle", "Miami", "Los Angeles"]
  states = DemocracyInAction::Helpers.state_options_for_select

  attributes_for :event do |a|
    a.calendar = default_calendar
    a.host = default_user
    a.name = "Step It Up"
    a.location = "1 Market St."
    a.description = "This event will be awesome."
    a.city = cities[rand(cities.length)]
    a.state = states[rand(states.length)].last
    a.postal_code = "94114"
    a.start = (start = Time.now + 2.months)
    a.end = start + 2.hours
    a.country_code = 'something that will not trigger set_district'
	end

=begin
  attributes_for :service_object do |a|
    a.mirrored = default_user
    a.remote_service = "Salesforce"
    a.remote_id = '555'
    a.remote_type = 'Contact'
  end
=end

  attributes_for :hostform do |a|
    
	end

  attributes_for :politician_invite do |a|
    
	end

  attributes_for :politician do |a|
    
	end

  attributes_for :press_link do |a|
    
	end

  attributes_for :report do |a|
    a.status = Report::PUBLISHED
    a.event = default_event
    a.user = default_user
    a.text = "this event was dope"
    a.akismet_params = {}
    a.embed_data = {'0' => {:caption => 'video!', :html => '<object width="425" height="344"><param name="movie" value="http://www.youtube.com/v/f31PLcCXD0U&hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><embed src="http://www.youtube.com/v/f31PLcCXD0U&hl=en&fs=1" type="application/x-shockwave-flash" allowfullscreen="true" width="425" height="344"></embed></object>'}} 
    a.press_link_data = {'0' => {:url => 'http://press.link.example.com', :text => 'link!'}}
	end

  attributes_for :role do |a|
    a.title = "admin"
	end

  attributes_for :rsvp do |a|
    
	end

  attributes_for :site do |a|
   a.host = "events." + String.random(10) + ".org"
   a.theme = "stepitup"
	end

  attributes_for :tagging do |a|
    
	end

  attributes_for :tag do |a|
    
	end

  attributes_for :trigger do |a|
    
	end

  attributes_for :user do |a|
    a.first_name = "Jon"
    a.last_name = "Warnow"
    a.phone = "555-555-5555"
    a.email = "jon." + String.random(8) + "@stepitup.org"  #"jon.warnow@siu.org"
    a.street = "1370 Mission St."
    a.city = "San Francisco"
    a.state = "CA"
    a.postal_code = "94114"
    a.password = "secret" 
    a.password_confirmation = "secret" 
    a.activated_at = 1.day.ago
    a.site = default_site
	end

  attributes_for :zip_code do |a|
    
	end

end
