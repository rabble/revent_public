require File.dirname(__FILE__) + '/../../spec_helper.rb'

if File.exists?(File.join(RAILS_ROOT, 'test','config', 'salesforce-config.yml'))
  describe SalesforceBase do
    fixtures :users
  #  it "should establish connection with Salesforce" do
  #    Site.stub!(:current_config_path).and_return(File.join(RAILS_ROOT, 'test', 'config'))
  #    Salesforce::Contact.count # use this to initiate connection
  #    Salesforce::Base.connected?.should be_true
  #  end

  #  it "should raise an error when accessed with no salesforce configuration" do
  #    Site.stub!(:current_config_path).and_return('non_existant_path')
  #    lambda { act! }.should raise_error(ActiveRecord::ConnectionNotEstablished)
  #  end

    before do
      Site.stub!(:config_path).and_return(File.join(RAILS_ROOT,'test','config'))
      SalesforceContact.make_connection(6)
      @sf_contact = SalesforceContact.new(SalesforceContact.translate(User.find(:first)))
    end

    it 'should save contact by id' do
      pending
      @sf_contact.new_record?.should be_true
      lambda {@sf_contact.save}.should change(SalesforceContact,:count)
      #lambda {SalesforceContact.create!(attribs)}.should_not raise_error
    end
    it 'should find saved contact by email' do
      pending
      @sf_contact.save
      SalesforceContact.find(@sf_contact.id).id.should == @sf_contact.id
    end

  end
else
  puts "No test/config/salesforce-config.yml found. Skipping Salesforce remote tests."
end
