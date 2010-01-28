require File.dirname(__FILE__) + "/../spec_helper"

describe SalesforceParticipant do
  describe "for salesforce contact" do
    it "should use salesforce contact for attendee if it exists" do
      @sf_contact = stub(ServiceObject, :remote_id => String.random(10)) 
      @user = stub(User, :salesforce_object => @sf_contact, :name => 'test name')
      rsvp = stub(Rsvp, :user => @user, :event => stub('stub').as_null_object, :created_at => Time.now)
      SalesforceParticipant.translate_rsvp(rsvp)[:contact_id__c].should == @sf_contact.remote_id
    end
    it "should create a salesforce contact for attendee if it does not exist" do
      @user = stub(User, :salesforce_object => nil, :name => 'firstly lastly')
      rsvp = stub(Rsvp, :user => @user, :event => stub('stub').as_null_object, :created_at => Time.now)
      @sf_contact = stub(SalesforceContact, :id => '1234ABCD')
      SalesforceContact.should_receive(:save_from_user).with(@user).and_return(@sf_contact)
      SalesforceParticipant.translate_rsvp(rsvp)[:contact_id__c].should == @sf_contact.id
    end
  end
  describe "for salesforce event" do
    it "should use it for event attendee if it exists" do
      @sf_event = stub(ServiceObject, :remote_id => String.random(10)) 
      @event = stub(Event, :salesforce_object => @sf_event, :name => 'Test Event')
      rsvp = stub(Rsvp, :user => stub('stub').as_null_object, :event => @event, :created_at => Time.now)
      SalesforceParticipant.translate_rsvp(rsvp)[:event_id__c].should == @sf_event.remote_id
    end
    it "should create salesforce event if it does not exist" do
      @event = stub(Event, :salesforce_object => nil, :name => 'Test Event 2')
      rsvp = stub(Rsvp, :user => stub('stub').as_null_object, :event => @event, :created_at => Time.now)
      @sf_event = stub(SalesforceEvent, :id => String.random(10)) 
      SalesforceEvent.should_receive(:save_from_event).with(@event).and_return(@sf_event)
      SalesforceParticipant.translate_rsvp(rsvp)[:event_id__c].should == @sf_event.id
    end
  end
  it "should translate an rsvp into a salesforce Participant" do 
    pending
    r = create_rsvp
    SalesforceParticipant.translate_rsvp(rsvp) 
  end
  describe "report" do
    before do
      SalesforceParticipant.stub!(:make_connection).and_return(true)
      Site.stub!(:current).and_return(stub(Site, :id => 4, :salesforce_enabled? => false))
      @report = new_report
      @report.event.create_salesforce_object(:remote_service => 'Salesforce', :remote_type => 'rEvent', :remote_id => '4321DEFB')
      @report.user.create_salesforce_object(:remote_service => 'Salesforce', :remote_type => 'Contact', :remote_id => '2222PPPP')
    end
    it "should create a Salesforce Participant" do
      SalesforceParticipant.stub!(:table_name).and_return('rParticipant')
      SalesforceParticipant.should_receive(:create).and_return(stub('Participant', :id => '3333GGGG'))
      SalesforceParticipant.save_from_report(@report)
    end
  end
end
