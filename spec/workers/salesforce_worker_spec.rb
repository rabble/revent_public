require File.dirname(__FILE__) + '/../spec_helper.rb'

describe SalesforceWorker do
  before do
    @sf_contact = mock(SalesforceContact, :id => 222, :new_record? => true, :save => true)
    SalesforceContact.stub!(:save_from_user).and_return(@sf_contact)

    Site.stub!(:current).and_return(stub(Site, :id => 1, :salesforce_enabled? => false))
    @user = create_user(:deferred => true)
  end

  it "should pass the user id" do
    User.should_receive(:find).with(@user.id).and_return(@user)
    SalesforceWorker.new.save_contact(:user_id => @user.id)
  end
  
  it "should create a contact" do
    User.stub!(:find).and_return(@user)
    SalesforceContact.should_receive(:save_from_user).and_return(@sf_contact)
    SalesforceWorker.new.save_contact(:user_id => @user.id)
  end

  it "should delete a contact" do
    SalesforceContact.should_receive(:delete_contact).with(@sf_contact.id)
    SalesforceWorker.new.delete_contact(@sf_contact.id)
  end

  it "should delete a event" do
    SalesforceEvent.should_receive(:delete_event).with('123ABC')
    SalesforceWorker.new.delete_event('123ABC')
  end
end
