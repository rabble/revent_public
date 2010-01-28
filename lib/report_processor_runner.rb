#!/usr/bin/env ruby

require 'rubygems'
require 'daemons'

require File.dirname(__FILE__) + "/report_processor.rb"
Daemons.run_proc("report_processor", 
                 :log_output => true, 
                 :dir_mode => :normal, 
                 :dir => File.dirname(__FILE__) + "/../log") do
  ReportProcessor.run
end
