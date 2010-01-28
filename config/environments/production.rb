# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Need to disable caching of templates for multisite plugin (i.e. theme_support)
# to work.  This does not effect page caching.
config.action_view.cache_template_loading = false
config.action_view.cache_template_extensions = false

# Use a different logger for distributed setups
#require 'syslog_logger'
#config.logger = RAILS_DEFAULT_LOGGER = SyslogLogger.new('daysofaction')
#require 'hodel_3000_compliant_logger'
#config.logger = Hodel3000CompliantLogger.new(config.log_path)
#config.logger.level = Logger::INFO

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

config.active_record.verification_timeout = 14400

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors if you bad email addresses should just be ignored
# config.action_mailer.raise_delivery_errors = false

#ActionMailer::Base.delivery_method = :sendmail
ActionMailer::Base.smtp_settings = {
   :domain      => "events.radicaldesigns.org",
   :address     => 'npomail.electricembers.net',
   :port        => 587,
   :user_name		=> 'events@radicaldesigns.org',
   :password		=> 'fuckhotmail',
   :authentication	=> :login
   }

#require 'tlsmail'
#Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)

=begin
ActionMailer::Base.delivery_method = :msmtp

module ActionMailer
  class Base
    def perform_delivery_msmtp(mail)
      IO.popen("/usr/bin/msmtp -t -C /var/www/daysofaction/shared/msmtprc -a provider --", "w") do |sm|
        sm.puts(mail.encoded.gsub(/\r/, ''))
        sm.flush
      end
      if $? != 0
        # why >> 8? because this is posix and exit code is in bits 8-16
        logger.error("failed to send mail errno #{$? >> 8}")
      end
    end
  end
end
=end

DIA_ENABLED = true

CACHE = MemCache.new ['127.0.0.1:11211']
require 'memcache_util'

require 'mem_cache_fragment_store'
ActionController::Base.fragment_cache_store = :mem_cache_fragment_store, CACHE
config.action_controller.session_store = :mem_cache_store

begin
  require 'flickr'
  Flickr::API_KEY='fcf5d360d3eb7543605059f2017ef971'
  Flickr::SHARED_SECRET='db8221678454fae6'
rescue MissingSourceFile
end
