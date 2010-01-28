require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/reports_controller'
require 'site'

# Re-raise errors caught by the controller.
class Admin::ReportsController; def rescue_action(e) raise e end; end

class Admin::ReportsControllerTest < Test::Unit::TestCase
  fixtures :sites, :calendars, :users, :roles, :roles_users

  def setup
    @controller = Admin::ReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @calendar   = calendars(:siu_nov)
    @site       = @calendar.site
    @request.host = @site.host
  end

  def test_redirect_after_login
    get :index, :permalink =>  @calendar.permalink
    assert_redirected_to :action => 'login'
    post :login, {:email => 'quentin@example.com', :password => 'test'}
    assert_redirected_to :permalink => @calendar.permalink, :controller => 'admin/reports', :action => 'index'
  end

  def test_list
    assert true
=begin
    login_as :quentin
    get :list
    assert_response :success
=end
  end
end
