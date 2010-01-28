class SalesforceContact < SalesforceBase
  has_one :salesforce_object, :as => :remote, :class_name => 'ServiceObject'

  #  cannot set_table_name here because we need a valid connection (because it connects!  when we do set_table_name!  wtf!!!!
  #  set_table_name "Contact"
  class << self
    def make_connection(id)
      config = File.join(Site.config_path(id), 'salesforce-config.yml')
      return unless File.exist?(config)
      establish_connection(YAML.load_file(config))
      set_table_name 'Contact'
    end

    def save_from_user(user) #create_with_user_and_checking_if_we_use_salesforce
      return unless self.make_connection(user.site_id)
      attribs = user.is_a?(User) ? translate(user) : user
      if user.salesforce_object
        sf_contact = SalesforceContact.update(user.salesforce_object.remote_id, attribs)
      else
        if sf_contact = SalesforceContact.find(:first, :conditions => {:email => user.email})
          sf_contact = SalesforceContact.update(sf_contact.id, attribs)
        else
          sf_contact = SalesforceContact.create(attribs)
        end
        user.create_salesforce_object(:remote_service => 'Salesforce', :remote_type => self.table_name, :remote_id => sf_contact.id)
      end
      sf_contact
    rescue ActiveSalesforce::ASFError => err
      logger.error("Error in SalesforceContact.save_from_user with user id #{user.id}: #{err}")
    end

    def translate(user)
      { :phone                => user.phone,
        :email                => user.email,
        :first_name           => user.first_name,
        :last_name            => user.last_name,
        :mailing_street       => user.street,
  #      :mailing_street2      => user.street_2,
        :mailing_city         => user.city,
        :mailing_state        => user.state,
        :mailing_country      => user.country,
        :mailing_postal_code  => user.postal_code }
    end

    def delete_contact(contact_id)
      transaction { delete(contact_id) }
    rescue ActiveSalesforce::ASFError => e
      raise e unless e.message =~ /ENTITY_IS_DELETED/
    end
  end
end
