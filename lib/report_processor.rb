ENV['RAILS_ENV'] = ENV['RAILS_ENV'] || $RAILS_ENV || 'production'
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')
require File.expand_path(File.dirname(__FILE__) + '/../lib/upload_to_flickr')
#ActiveRecord::Base.allow_concurrency = true #hopefully the reconnect trick will work intead

require 'starling'
require 'press_link'
require 'tag'
require 'site'
require 'calendar'
require 'user'
require 'trigger'

class ReportProcessor
  def self.run
    starling = Starling.new 'localhost:22122'
    loop do
      data = starling.get 'reports'
      begin
        Site.count #see if our connection is still ok
      rescue ActiveRecord::StatementInvalid
        # Our database connection has gone away, reconnect and retry this method
        ActiveRecord::Base.connection.reconnect!
        unless @retried_connection
          @retried_connection = true
          retry
        end
        raise
      end
      report = data[:report]
      attachments = data[:attachments]
      request = data[:request]
      Site.current = data[:site]
      flickr_tags = data[:flickr_tags]
      flickr_photoset = data[:flickr_photoset]
      puts "processing report #{report.id}"
      attachments.each do |a| 
        a[0].temp_data = a[1]
      	err_cnt = 0
      	begin
      	  a[0].save
      	rescue Errno::EPIPE
      	  puts 'caught broken pipe'
      	  err_cnt = err_cnt + 1
      	  sleep 0.25
      	  retry if err_cnt < 5
      	end
        a[0].tags = a[0].tag_depot if a[0].tag_depot
      end
      report.attachments = attachments.collect {|a| a[0]}
      upload_images_to_flickr(report.attachments, 
            :async => false,
            :site_id => Site.current.id, 
            :title => "#{report.event.name} - #{report.event.city}, #{report.event.state}",
            :tags =>  flickr_tags, 
            :photoset => flickr_photoset)
      puts 'uploaded to flickr'
      spam = report.check_akismet(request)
      puts 'checked with akismet, got: ' + spam
    end
  end
end

