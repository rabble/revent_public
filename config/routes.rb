ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

#  raise Calendar.find(:first).inspect => WORKS!!!
  map.home '', :controller => 'calendars', :action => 'show', :format => 'html'
  map.connect "logged_exceptions/:action/:id", :controller => "logged_exceptions"
  map.connect "logged_exceptions/:action.:format", :controller => "logged_exceptions"
  map.connect 'crossdomain.xml', :controller => 'cross_domain', :format => 'xml'

  # see http://dev.rubyonrails.org/changeset/6594 for 
  # edge rails solution to using resources and namespace
#  map.resources :calendars, :path_prefix => "admin", :controller => "admin/calendars" do |cal|
#    cal.resources :events
#  end

# work-around for issue with namespace collisions occurring due to app/controller/admin_controller.rb 
# should be cleaned-up to work automatically with admin namespace and perhaps resources 
  map.connect 'admin/users/:action/:id.:format', :controller => 'admin/users'
  map.connect 'admin/users/:action.:format', :controller => 'admin/users'
  map.connect 'admin/users/:action/:id', :controller => 'admin/users'

  map.connect 'admin/:permalink/events/:action/:id.:format', :controller => 'admin/events'
  map.connect 'admin/:permalink/events/:action.:format', :controller => 'admin/events'
  map.connect 'admin/:permalink/events/:action/:id', :controller => 'admin/events'
 
  map.connect 'admin/:permalink/reports/:action/:id.:format', :controller => 'admin/reports'
  map.connect 'admin/:permalink/reports/:action.:format', :controller => 'admin/reports'
  map.connect 'admin/:permalink/reports/:action/:id', :controller => 'admin/reports'
 
  map.connect 'admin/calendars/:action/:id.:format', :controller => 'admin/calendars'
  map.connect 'admin/calendars/:action.:format', :controller => 'admin/calendars'
  map.connect 'admin/calendars/:action/:id', :controller => 'admin/calendars'

  map.connect 'admin/triggers/:action/:id.:format', :controller => 'admin/triggers'
  map.connect 'admin/triggers/:action.:format', :controller => 'admin/triggers'
  map.connect 'admin/triggers/:action/:id', :controller => 'admin/triggers'

  map.connect 'admin/categories/:action/:id.:format', :controller => 'admin/categories'
  map.connect 'admin/categories/:action.:format', :controller => 'admin/categories'
  map.connect 'admin/categories/:action/:id', :controller => 'admin/categories'

  map.connect 'admin/hostforms/:action/:id.:format', :controller => 'admin/hostforms'
  map.connect 'admin/hostforms/:action.:format', :controller => 'admin/hostforms'
  map.connect 'admin/hostforms/:action/:id', :controller => 'admin/hostforms'

  map.connect 'admin/categories/:action/:id.:format', :controller => 'admin/categories'
  map.connect 'admin/categories/:action.:format', :controller => 'admin/categories'
  map.connect 'admin/categories/:action/:id', :controller => 'admin/categories'

  map.connect 'admin/reports/:action/:id.:format', :controller => 'admin/reports'
  map.connect 'admin/reports/:action.:format', :controller => 'admin/reports'
  map.connect 'admin/reports/:action/:id', :controller => 'admin/reports'

  map.connect 'admin/cache', :controller => 'admin/caches', :only => :delete, :action => 'destroy'
# end of work-around

  map.connect 'partners/:id', :controller => 'partners'
  map.connect 'partners/:id/rsvp/:event_id', :controller => 'partners'
  map.connect ':permalink/partners/:id', :controller => 'partners'

  map.with_options :controller => 'events', :action => 'new' do |m|
    m.signup ':permalink/signup/:partner_id', :defaults => {:partner_id => nil}
    m.connect 'calendars/:calendar_id/signup/:partner_id', :defaults => {:partner_id => nil}
    m.connect 'signup/:partner_id', :defaults => {:partner_id => nil}
  end

  map.connect '/attachments/:id1/:id2/*file', :controller => 'attachments', :action => 'show', :requirements => { :id1 => /\d+/, :id2 => /\d+/ }
  map.connect '/attachments/:id/*file', :controller => 'attachments', :action => 'show', :requirements => { :id => /\d+/ }

  map.with_options :controller => 'account' do |m|
    m.login   '/login',   :action => 'login'
    m.logout  '/logout',  :action => 'logout'
    m.profile '/profile', :action => 'profile'
  end  
  map.with_options :controller => 'account/events' do |m|
    m.connect '/profile/events/:id', :action => 'show', :requirements => {:id => /\d+/}
    m.connect '/profile/events/:action/:id'
  end
  map.with_options :controller => 'account/blogs' do |m|
    m.connect '/profile/blogs/:action/:id'
  end

  map.ally '/ally/:referrer', :controller => 'events', :action => 'ally', :defaults => {:referrer => ''}

  map.zip_search ":permalink/events/search/zip/:zip",  :controller => "events",
                                        :action => "search"
  map.state_search ":permalink/events/search/state/:state", :controller => "events",
                                           :action => "search",
                                           :requirements => { :state => /\w{2}/ }
  map.connect "events/search/zip/:zip",  :controller => "events",
                                        :action => "search"
  map.connect "events/search/state/:state", :controller => "events",
                                           :action => "search",
                                           :requirements => { :state => /\w{2}/ }

  map.report_state_search ":permalink/reports/search/state/:state", :controller => "reports",
                                           :action => "search",
                                           :requirements => { :state => /\w{2}/ }
  map.report_zip_search ":permalink/reports/search/zip/:zip",  :controller => "reports",
                                        :action => "search",
                                        :requirements => { :zip => /\d{5}/ }
  map.connect "reports/search/state/:state", :controller => "reports",
                                           :action => "search",
                                           :requirements => { :state => /\w{2}/ }
  map.connect "reports/search/zip/:zip",  :controller => "reports",
                                        :action => "search",
                                        :requirements => { :zip => /\d{5}/ }

  map.connect ':permalink/reports/photos/tagged/:tag', :controller => 'reports', :action => 'photos'
  map.connect ':permalink/reports/video/tagged/:tag', :controller => 'reports', :action => 'video'
  map.report ':permalink/reports/:event_id', :controller => 'reports', :action => 'show', :requirements => {:event_id => /\d+/}
  map.legacy_report 'reports/:event_id', :controller => 'reports', :action => 'redirect_to_show_with_permalink', :requirements => {:event_id => /\d+.*/}

  map.connect ':permalink/:controller/page/:page', :action => 'list'
  map.connect ':controller/page/:page', :action => 'list'
  map.connect ':controller/search/zip/:zip/:page', :action => 'search'

  map.connect ':permalink/events/show/:id', :controller => 'events', :action => 'show', :format => 'html'

  map.connect 'events/international/page/:page', :controller => 'events', :action => 'international'
  map.connect ':permalink/events/international/page/:page', :controller => 'events', :action => 'international'


  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action.:format'
  map.connect ':controller/:action/:id'

  map.connect ':permalink', :controller => 'calendars', :action => 'show' 
  map.connect ':permalink/:controller/:action/:id.:format'
  map.connect ':permalink/:controller/:action.:format'
  map.connect ':permalink/:controller/:action/:id'
end
