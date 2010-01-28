require File.dirname(__FILE__) + '/../spec_helper.rb'

describe User do
  before do
    DemocracyInAction::API.stub!(:process).and_return(1111)
    @site = create_site
    Site.stub!(:current).and_return(@site)
  end

  describe "when saved" do
    before do
      @user = new_user(:site => @site)
    end

    it "should not overwrite an existing password" do
      @user.password = @user.password_confirmation = "secret"
      @user.activated_at = 1.day.ago
      @user.save
      User.authenticate(@user.email, "secret").should == @user
    end

    it "should set a default password" do
      u = new_user(:password => nil, :password_confirmation => nil)
      u.save!
      u.crypted_password.should_not be_nil
    end

    it "should create a user" do
      assert_difference User, :count do
        @user.save
        assert !@user.new_record?, "#{@user.errors.full_messages.to_sentence}"
      end
    end

    it "should require a password" do
      lambda {
        @user.password = ""
        @user.password_confirmation = ""
        @user.save
        assert @user.errors.on(:password)
      }.should_not change( User, :count  )
    end

    it "should require password confirmation" do
      @user.password = "blah"
      @user.password_confirmation = "blahz"
      @user.save
      @user.errors.any? { |e| e.to_s =~ /confirmation/ }.should be_true
    end

    it "should require email" do
      assert_no_difference User, :count do
        @user.email = nil
        @user.save
        assert @user.errors.on(:email)
      end
    end
  end

  describe "when already existing" do
    before do
      @user = create_user(:password => "secret", :password_confirmation => "secret") 
      Site.stub!(:current).and_return(stub(Site, :id => @user.site_id, :salesforce_enabled? => false))
    end

    it "should not allow resetting the password with mass assignment" do
      @user.update_attributes(:password => 'new password', :password_confirmation => 'new password')
      User.authenticate(@user.email, 'new password').should be_nil
    end

    it "should allow resetting the password explicitly" do
      @user.password = 'new password'
      @user.password_confirmation = 'new password'
      @user.stub!(:sync_to_democracy_in_action)
      @user.save
      User.authenticate(@user.email, 'new password').should == @user
    end

    it "should not rehash a new password" do
      @user.update_attributes(:login => 'quentin2', :email => 'quentin2@example.com')
      assert_equal @user, User.authenticate('quentin2@example.com', 'secret')
    end

    it "should authenticate" do
      assert_equal @user, User.authenticate(@user.email, 'secret')
    end

    it "should set remember token" do
      @user.remember_me
      assert_not_nil @user.remember_token
      assert_not_nil @user.remember_token_expires_at
    end

    it "should unset remember token" do
      @user.remember_me
      assert_not_nil @user.remember_token
      @user.forget_me
      assert_nil @user.remember_token
    end
  end

  describe "integrates with DIA" do
    before do
      @user = new_user
      @dia_api = mock(DemocracyInAction::API)
      DemocracyInAction::API.stub!(:new).and_return(@dia_api)
      Site.stub!(:current_config_path).and_return(File.join(RAILS_ROOT,'test','config'))
    end

    it "should push user to DIA supporter" do
      pending
      @dia_api.should_receive(:process).twice.and_return('1111')
      @user.save
    end
  end

  describe "integrates with salesforce" do
    it "should pass itself to salesforce" do
      pending
      @user = new_user
      SalesforceContact.should_receive(:create_with_user).with(@user)
      @user.sync_to_salesforce
    end
    describe "deleting" do
      before do
        @user = new_user
        @user.site.stub!(:salesforce_enabled?).and_return(true)
        @user.build_salesforce_object(:remote_id => '444GGG')
      end
      it "should delete itself from salesforce" do
        SalesforceWorker.should_receive(:async_delete_contact).with(@user.salesforce_object.remote_id)
        @user.delete_from_salesforce
      end
      it "should log the error with a workling failure" do
        SalesforceWorker.stub!(:async_delete_contact).and_raise(Workling::WorklingError.new)
        @user.logger.should_receive(:error)
        @user.delete_from_salesforce.should be_true
      end
    end
  end

  describe "accepts custom attributes" do
    before do
      @user = new_user
    end
    it "accepts them as a hash" do
      @user.custom_attributes_data = { :ethnicity => 'Kentucky' }
      @user.custom_attributes_data.ethnicity.should == 'Kentucky'
    end

    it "saves and reloads with them intact" do
      @user.custom_attributes_data = { :ethnicity => 'Kentucky' }
      @user.save!
      usr = User.find @user.id
      usr.custom_attributes_data.ethnicity.should == 'Kentucky'
    end
  end
end
