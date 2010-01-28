require File.dirname(__FILE__) + '/../../test_helper'
require 'account/reports_controller'

# Re-raise errors caught by the controller.
class Account::ReportsController; def rescue_action(e) raise e end; end

class Account::ReportsControllerTest < Test::Unit::TestCase
  fixtures :reports, :users, :roles, :roles_users, :sites, :calendars, :events

  def setup
    @controller = Account::ReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @calendar = calendars(:siu_nov)
    @site = @calendar.site
    @request.host = @site.host
  end

  def test_edit
    login_as :quentin
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:report)
    assert assigns(:report).valid?
  end

  def test_update
    login_as :quentin
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 3
  end

  def test_destroy
    login_as :quentin
    assert_not_nil Report.find(1)

    post :destroy, :id => 1
    assert_response :success

    assert_raise(ActiveRecord::RecordNotFound) { Report.find(1) }
  end
end
