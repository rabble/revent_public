require File.dirname(__FILE__) + '/../../spec_helper.rb'

if File.exists?(File.join(RAILS_ROOT, 'test','config', 'salesforce-config.yml'))
  describe SalesforceEvent do
    before do
      @config = File.join(RAILS_ROOT,'test','config')
      Site.stub!(:config_path).and_return(@config)
      Site.stub!(:current).and_return(stub(Site, :id => 1, :salesforce_enabled? => false))
      #SalesforceEvent.stub!(:set_table_name).and_return(true)
    end
    it "should be able to establish a connection" do
      lambda {SalesforceEvent.establish_connection(YAML.load_file(@config + '/salesforce-config.yml'))}.should_not raise_error
    end
    it "should make a connection" do
      lambda {SalesforceEvent.make_connection(1)}.should_not raise_error
    end
    it "should connect to salesforce database" do
      pending # suspect 
      SalesforceEvent.should_receive(:establish_connection).and_return(true)
      SalesforceEvent.make_connection(1)
    end
    it "should describe the SalesforceEvent when connected" do
      SalesforceEvent.make_connection(1)
      SalesforceEvent.inspect.should match(/datetime, start__c: datetime, end__c:/)
    end

    EVENT_ATTRIBUTES = { 
      :location => "1 Market St.",
      :description => "This event will be awesome.",
      :city => "New York",
      :state => "NY",
      :postal_code => "94114",
      :start => Time.now + 2.months,
      :end => Time.now + 2.months + 2.hours } 

    describe "when creating" do
      before(:all) do
        @config = File.join(RAILS_ROOT,'test','config')
        Site.stub!(:config_path).and_return(@config)
        Site.stub!(:current).and_return(stub(Site, :id => 1, :salesforce_enabled? => false))
        SalesforceEvent.make_connection(12)
        SalesforceContact.make_connection(12)
        @event = create_event(EVENT_ATTRIBUTES)
        @event.host.stub!(:salesforce_object).and_return(stub('sf_object', :remote_id => ""))
        @sf_event = SalesforceEvent.create(SalesforceEvent.translate(@event))

        @event.create_salesforce_object(:remote_service => 'Salesforce', :remote_type => 'rEvent', :remote_id => @sf_event.id)
      end

      EVENT_ATTRIBUTES.each do |key, value|
        it "should contain #{key} from event object" do
          @sf_event.attributes["#{key}__c"].should == value
        end
      end
      it "should find the object it created" do
        SalesforceEvent.find(@sf_event.id).id.should == @sf_event.id
      end
      describe "update" do
        before do
          @sf_event.city__c = "San Francisco"
          @sf_event.state__c = "CA"
        end
        it "save should return true" do
          @sf_event.save.should be_true
        end
        it "should update the object it created" do
          @sf_event.save
          SalesforceEvent.find(@sf_event.id).city__c.should == "San Francisco" &&
          SalesforceEvent.find(@sf_event.id).state__c.should == "CA"
        end
      end
      describe "destroy" do 
        it "event should no longer exist" do
          SalesforceEvent.delete_event(@sf_event.id)
          lambda{SalesforceEvent.find(@sf_event.id)}.should raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end
else
  puts "No test/config/salesforce-config.yml found. Skipping Salesforce remote tests."
end
