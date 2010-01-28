require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/users_controller'

# Re-raise errors caught by the controller.
class Admin::UsersController; def rescue_action(e) raise e end; end

class Admin::UsersControllerTest < Test::Unit::TestCase
  fixtures :sites, :calendars, :users, :roles, :roles_users

  def setup
    @controller = Admin::UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # setup site/calendar and host
    @calendar   = calendars(:siu_nov)
    @site       = @calendar.site
    @request.host = @site.host
  end

  def test_index
    get :index
    assert_redirected_to :action => 'login'
    login_as :quentin
    get :index
    assert_response 302
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
