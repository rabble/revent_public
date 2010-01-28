# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

config.action_view.cache_template_extensions         = false
config.action_view.debug_rjs                         = true

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

config.to_prepare do
  load 'config/initializers/cartographer.rb'
end

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :domain => 'events.radicaldesigns.org',
  :perform_deliveries => true,
  :address => 'npomail.electricembers.net',
  :port => 25,
  :authentication => :login,
  :user_name => 'events@radicaldesigns.org',
  :password => 'fuckhotmail'
}

DIA_ENABLED = false

begin
  require 'flickr'
  Flickr::API_KEY='ac682326488deff72b45939163d639ba'
  Flickr::SHARED_SECRET='57d0e673eee6114e'
rescue MissingSourceFile
end

begin
  CACHE = MemCache.new ['127.0.0.1:11211']
  require 'memcache_util'
rescue
end
