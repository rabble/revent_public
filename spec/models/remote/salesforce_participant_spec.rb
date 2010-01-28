require File.dirname(__FILE__) + '/../../spec_helper.rb'

if File.exists?(File.join(RAILS_ROOT, 'test','config', 'salesforce-config.yml'))
  describe SalesforceParticipant do
    before(:all) do
      @config = File.join(RAILS_ROOT,'test','config')
      Site.stub!(:config_path).and_return(@config)
      Site.stub!(:current).and_return(stub(Site, :id => 1, :salesforce_enabled? => false))
      SalesforceContact.make_connection nil
      SalesforceEvent.make_connection nil
      SalesforceParticipant.make_connection nil
      @contact = SalesforceContact.find(:first)
      @event = SalesforceEvent.find(:first)
    end

    it "should create participants" do
      #NOTE: maybe we should create these?
      p = SalesforceParticipant.create :contact_id__c => @contact.id, :event_id__c => @event.id, :type__c => 'attendee'
      p.id.should_not be_blank
    end
    
    it "should create a Salesforce Participant object" do
      sp = SalesforceParticipant.create(
        :name => "reported",
        :contact_id__c => @contact.id,
        :event_id__c => @event.id,
        :type__c => 'reporter')
      lambda{SalesforceParticipant.find(sp.id)}.should_not raise_error(ActiveRecord::RecordNotFound)
    end
    it "should set the type to reporter" do 
      sp = SalesforceParticipant.create(
        :name => "reported", 
        :contact_id__c => @contact.id,
        :event_id__c => @event.id,
        :type__c => 'reporter')
      SalesforceParticipant.find(sp.id).type__c.should == 'reporter'
    end
=begin
    it "should update a contact if one already exists with the users email" do
      user = new_user(:first_name => 'bob')
      contact_id = SalesforceContact.create(:email => user.email, :last_name => user.last_name, :first_name => 'charlie').id
      SalesforceContact.save_from_user(user)
      SalesforceContact.find(contact_id).first_name.should == 'bob'
    end

    it "should delete contacts" do
      contact_id = SalesforceContact.create(:email => 'test@example.com', :last_name => 'last').id
      SalesforceContact.delete_contact(contact_id)
      lambda { SalesforceContact.find(contact_id) }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not die if contact is already deleted" do
      contact_id = SalesforceContact.create(:email => 'test@example.com', :last_name => 'last').id
      SalesforceContact.delete_contact(contact_id)
      lambda { SalesforceContact.delete_contact(contact_id) }.should_not raise_error
    end

    it "should raise error if asf raises a different kind of error" do
      contact_id = SalesforceContact.create(:email => 'test@example.com', :last_name => 'last').id
      error = ActiveSalesforce::ASFError.new(SalesforceContact.logger, 'bad')
      SalesforceContact.delete_contact(contact_id)
      SalesforceContact.should_receive(:delete).and_raise(error)
      lambda { SalesforceContact.delete_contact(contact_id) }.should raise_error
    end
=end
  end
else
  puts "No test/config/salesforce-config.yml found. Skipping Salesforce remote tests."
end
