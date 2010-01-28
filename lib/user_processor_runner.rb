#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

require File.dirname(__FILE__) + "/user_processor.rb"
Daemons.run_proc("user_processor", 
                 :log_output => true, 
                 :dir_mode => :normal, 
                 :dir => File.dirname(__FILE__) + "/../log") do
  UserProcessor.run
end
