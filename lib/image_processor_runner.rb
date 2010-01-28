#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

require File.dirname(__FILE__) + "/image_processor.rb"
Daemons.run_proc("image_processor", 
                 :log_output => true, 
                 :dir_mode => :normal, 
                 :dir => File.dirname(__FILE__) + "/../log") do
  ImageProcessor.run
end
