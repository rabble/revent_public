class SalesforceWorker < Workling::Base
  def save_contact(options={})
    RAILS_DEFAULT_LOGGER.info "SalesforceWorker received user id: #{options[:user_id]}"
    SalesforceContact.save_from_user(User.find(options[:user_id]))
  end

  def delete_contact(contact_id)
    SalesforceContact.delete_contact(contact_id)
  end

  def save_event(options={})
    RAILS_DEFAULT_LOGGER.info "SalesforceWorker received event id: #{options[:event_id]}"
    SalesforceEvent.save_from_event(Event.find(options[:event_id]))
  end

  def delete_event(sf_event_id)
    SalesforceEvent.delete_event(sf_event_id)
  end

  def save_participant(options={})
    SalesforceParticipant.save_from_rsvp(Rsvp.find(options[:rsvp_id])) if options[:rsvp_id]
    SalesforceParticipant.save_from_report(Report.find(options[:report_id])) if options[:report_id]
  end

  def delete_participant(participant_id)
    SalesforceParticipant.delete(participant_id)
  end
end
