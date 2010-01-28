class SalesforceParticipant < SalesforceBase
  has_one :salesforce_object, :as => :remote, :class_name => 'ServiceObject'

  class << self
    def make_connection(id)
      config = File.join(Site.config_path(id), 'salesforce-config.yml')
      return unless File.exist?(config)
      establish_connection(YAML.load_file(config))
      set_table_name 'rParticipant'
    end

    def save_from_report(report)
      return unless self.make_connection(report.user.site_id)
      user = report.user
      event = report.event
      sf_contact_id = user.salesforce_object ? 
        user.salesforce_object.remote_id : SalesforceContact.save_from_user(user).id
      sf_event_id = event.salesforce_object ? 
        event.salesforce_object.remote_id : SalesforceEvent.save_from_event(event).id
      sf_participant = SalesforceParticipant.create(
          :name => "#{user.name} reported on #{report.event.name}", 
          :contact_id__c => sf_contact_id, 
          :event_id__c => sf_event_id, 
          :type__c => 'reporter')
      report.create_salesforce_object(
          :remote_service => 'Salesforce', 
          :remote_type => self.table_name, 
          :remote_id => sf_participant.id)
      sf_participant
    rescue ActiveSalesforce::ASFError => err
      logger.error("Error in SalesforceParticipant.save_from_report with report id #{report.id}: #{err}")
    end

    def save_from_rsvp(rsvp) #create_with_user_and_checking_if_we_use_salesforce
      return unless self.make_connection(rsvp.user.site_id)
      attribs = self.translate_rsvp(rsvp)
      sf_rsvp = SalesforceParticipant.create(attribs)
      rsvp.create_salesforce_object(:remote_service => 'Salesforce', :remote_type => self.table_name, :remote_id => sf_rsvp.id)
      sf_rsvp
    rescue ActiveSalesforce::ASFError => err
      logger.error("Error in SalesforceParticipant.save_from_user with user id #{rsvp.user.id}: #{err}")
    end

    def translate_rsvp(rsvp)
      user = rsvp.user
      sf_contact_id = user.salesforce_object ? 
        user.salesforce_object.remote_id : SalesforceContact.save_from_user(user).id
      event = rsvp.event
      sf_event_id = event.salesforce_object ? 
        event.salesforce_object.remote_id : SalesforceEvent.save_from_event(event).id
      { :name => "#{rsvp.user.name} is attending #{rsvp.event.name}", 
        :contact_id__c  => sf_contact_id,
        :event_id__c => sf_event_id,
        :type__c => 'attendee'}
    end

    def delete_participant(participant_id)
      transaction { delete(participant_id) }
    rescue ActiveSalesforce::ASFError => e
      raise e unless e =~ /ENTITY_IS_DELETED/ 
    end
  end
end
