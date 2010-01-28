ENV['RAILS_ENV'] = ENV['RAILS_ENV'] || 'production'
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')
ActiveRecord::Base.allow_concurrency = true

#require 'starling_client'
require 'starling'
require 'user'
require 'site'
require 'democracy_in_action_object'
class UserProcessor
  def self.run
    queue = Starling.new 'localhost:22122'
    loop do
      data = queue.get 'users'
      user = data[:user]
      Site.current = data[:site]
      puts 'processing user ' + user.full_name
      user.deferred = false
      user.sync_to_democracy_in_action
    end
  end
end
