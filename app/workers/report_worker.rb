require_dependency 'user'
require_dependency 'democracy_in_action_object'
require_dependency 'press_link'

class ReportWorker < Workling::Base
  def save_report(report)
    Site.current = report.event.calendar.site
    ActionController::Base.page_cache_directory = File.join([RAILS_ROOT, (RAILS_ENV == 'test' ? 'tmp' : 'public'), 'cache', Site.current.host]) #aka, set_cache_root
    # might need to make this a Report.save
    # so we can use it in manage your event
    report.move_to_temp_files!
    report.save
  rescue NoMethodError
    logger.warn( "Report creation failed for event #{report.event_id}" )
  end
end
