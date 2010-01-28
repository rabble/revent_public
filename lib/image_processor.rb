ENV['RAILS_ENV'] = ENV['RAILS_ENV'] || 'production'
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')
ActiveRecord::Base.allow_concurrency = true

require 'starling'
require 'application'
require 'admin/reports_controller'
require 'site'
require 'attachment'

class ImageProcessor
  def self.run
    queue = Starling.new 'localhost:22122'
    loop do
      data = queue.get 'images'
      Site.current = Site.find(data[:site_id])
      puts 'zipping'
      Admin::ReportsController.zip_em_up(data[:permalink], data[:timestamp], data[:images])
    end
  end
end
