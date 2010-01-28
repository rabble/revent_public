require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

require 'mocha'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase
  fixtures :users, :sites, :calendars

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @emails = ActionMailer::Base.deliveries 
    @emails.clear

    @calendar = calendars(:siu_nov)
    @site = @calendar.site
    @request.host = @site.host
  end

  def test_should_login_and_redirect
    post :login, :email => 'quentin@example.com', :password => 'test'
    assert session[:user]
    assert_response :redirect
  end

=begin
  def test_should_login_and_redirect_with_democracy_in_action
    set_use_democracy_in_action_auth

    post :login, :email => 'test@test.com', :password => 'password'
    assert @controller.site.use_democracy_in_action_auth?
    assert session[:user]
    assert_equal session[:user].class, DemocracyInActionSupporter
    assert session[:user].Email='test@test.com'
    assert_response :redirect
  end
=end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'quentin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  def test_should_fail_login_and_not_redirect_with_democracy_in_action
    set_use_democracy_in_action_auth
    post :login, :email => 'test@test.com', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

=begin
  def test_profile_with_democracy_in_action
    set_use_democracy_in_action_auth
    post :login, :email => 'test@test.com', :password => 'password'
    get :profile
    assert_response :success
    assert_template 'profile'
  end
=end

  def test_should_allow_signup
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    assert_difference User, :count do
      create_user
      assert_response :redirect
    end
  end

=begin
  def test_should_require_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end
=end

  def test_should_require_password_on_signup
    assert_no_difference User, :count do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference User, :count do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference User, :count do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  def test_should_logout
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  def test_should_remember_me
    post :login, :email => 'quentin@example.com', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    post :login, :login => 'quentin', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end
  
  def test_should_delete_token_on_logout
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    login_as :quentin
    get :logout
    assert_equal @response.cookies["auth_token"], []
  end

  def test_should_login_with_cookie
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :index
    assert !@controller.send(:logged_in?)
  end

  def test_should_activate_user_and_send_activation_email
    get :activate, :id => users(:aaron).activation_code
#    assert_equal 1, @emails.length
#    assert(@emails.first.subject =~ /Your account has been activated/)
#    assert(@emails.first.body    =~ /#{assigns(:user).login}, your account has been activated/)
  end

  def test_should_not_activate_nil
    get :activate, :id => nil
    assert_activate_error
  end

  def test_should_not_activate_bad
    get :activate, :id => 'foobar'
    assert flash.has_key?(:error), "Flash should contain error message." 
    assert_activate_error
  end

  def assert_activate_error
    assert_response :success
    assert_template "./account/activate" #weird.  i think theme_support makes it relative path.
  end

  def test_should_forget_password
    post :forgot_password, :email => 'quentin@example.com'
    assert_response :redirect
    assert flash.has_key?(:notice), "Flash should contain notice message." 
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Request to change your password/)
  end

  def test_should_not_forget_password
    post :forgot_password, :email => 'invalid@email'
    assert_response :success
    assert flash.has_key?(:notice), "Flash should contain notice message." 
    assert_equal 0, @emails.length
  end

  def test__reset_password__valid_code_and_password__should_reset
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    @user = users(:aaron)
    @user.forgot_password && @user.save
    @emails.clear
    post :reset_password, :id => @user.password_reset_code, :password  => "new_password", :password_confirmation => "new_password" 

    assert_match("Password reset", flash[:notice])
    assert_equal 1, @emails.length # make sure that it e-mails the user notifying that their password was reset
    assert_equal(@user.email, @emails.first.to[0], "should have gone to user") 

    # Make sure that the user can login with this new password
    assert(User.authenticate(@user.email, "new_password"), "password should have been reset")
  end

  def test__reset_password__valid_code_but_not_matching_password__shouldnt_reset
    DemocracyInAction::API.any_instance.stubs(:process).returns(1111) unless connect?
    @user = users(:aaron)
    @user.forgot_password && @user.save
    @emails.clear
    post :reset_password, :id => @user.password_reset_code, :password  => "new_password", :password_confirmation => "not matching password" 

    assert_equal(0, @emails.length)
    assert_match("Password mismatch", flash[:notice])

    assert(!User.authenticate(@user.login, "new_password"), "password should not have been reset")
  end

  def test__reset_password__invalid_code__should_show_error
    post :reset_password, :id => "Invalid Code", :password  => "new_password", :password_confirmation => "not matching password" 

    assert_match(/invalid password reset code/, flash[:notice])
  end

  protected
    def create_user(options = {})
      post :signup, :user => { :login => 'quire', :email => 'quire@example.com', 
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
    
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end

    def set_use_democracy_in_action_auth
      s = DemocracyInActionSupporter.new(:Email => 'test@test.com', :Password => Digest::MD5.hexdigest('password'))
      DemocracyInActionSupporter.stubs(:find).returns(s)
      @request.host = sites(:stepitup).host
    end
end
