require File.dirname(__FILE__) + '/../../spec_helper.rb'

if File.exists?(File.join(RAILS_ROOT, 'test','config', 'salesforce-config.yml'))
  describe SalesforceContact do
    before(:all) do
      @config = File.join(RAILS_ROOT,'test','config')
      Site.stub!(:config_path).and_return(@config)
      Site.stub!(:current).and_return(stub(Site, :id => 1, :salesforce_enabled? => false))
      SalesforceContact.make_connection nil
      #SalesforceContact.find(:all).each {|s| SalesforceContact.delete_contact(s.id) rescue ActiveSalesforce::ASFError}
    end
    it "should update a contact if one already exists with the users email" do
      SalesforceContact.stub!(:make_connection).and_return(true)
      bob = new_user(:first_name => 'bob', :site_id => 1)
      sf_charlie = SalesforceContact.create(:email => bob.email, :last_name => bob.last_name, :first_name => 'charlie')
      contact_id = sf_charlie.id
      sf_bob = SalesforceContact.save_from_user(bob)
      SalesforceContact.find(contact_id).first_name.should == 'bob'
    end
  end

  describe "SalesforceContact delete" do
    before do
      @config = File.join(RAILS_ROOT,'test','config')
      Site.stub!(:config_path).and_return(@config)
      @user = create_user(:email => 'test@example.com', :last_name => 'lastly')
      @contact = SalesforceContact.save_from_user(@user)
    end

    it "should delete contacts" do
      SalesforceContact.delete_contact(@contact.id)
      lambda { SalesforceContact.find(@contact.id) }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it "should not die if contact is already deleted" do
      SalesforceContact.delete_contact(@contact.id)
      lambda { SalesforceContact.delete_contact(@contact.id) }.should_not raise_error
    end

    it "should raise error if asf raises a different kind of error" do
      error = ActiveSalesforce::ASFError.new(SalesforceContact.logger, 'bad')
      SalesforceContact.should_receive(:delete).and_raise(error)
      lambda { SalesforceContact.delete_contact(@contact.id) }.should raise_error
    end
  end
else
  puts "No test/config/salesforce-config.yml found. Skipping Salesforce remote tests."
end
