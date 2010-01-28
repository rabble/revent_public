require File.dirname(__FILE__) + '/../spec_helper'

describe ServiceObject do
  before do 
    SalesforceWorker.stub!(:async_save_contact).and_return(true)
    @user = create_user
  end
  it 'should associate with a user' do
    @user.create_salesforce_object(:remote_service => 'Salesforce', :remote_type => 'Contact', :remote_id => '1111')
    @user.salesforce_object.remote_id.should == '1111'
  end
end
