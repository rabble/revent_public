events = Event.find(:all, :conditions => ["events.end <= ? AND events.end > ?", Time.now, 1.day.ago])
events.each do |e|
  trigger = nil
  if e.calendar.triggers
    trigger = e.calendar.triggers.find_by_name("Report Host Reminder") 
  elsif e.calendar.site.triggers
    trigger = e.calendar.site.triggers.find_by_name("Report Host Reminder")
  end
  TriggerMailer.deliver_trigger(trigger, e.host, e, e.calendar.site.host) if trigger
end
