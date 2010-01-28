require File.dirname(__FILE__) + '/../../test_helper'
require 'account/events_controller'

require 'mocha'

# Re-raise errors caught by the controller.
class Account::EventsController; def rescue_action(e) raise e end; end

class Account::EventsControllerTest < Test::Unit::TestCase
  fixtures :users, :sites, :events, :calendars

  def setup
    @controller = Account::EventsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    s = DemocracyInActionSupporter.new(:Email => 'test@test.com', :Password => Digest::MD5.hexdigest('password'), :key => 1)
    DemocracyInActionSupporter.stubs(:find).returns(s)
    e = DemocracyInActionEvent.new(:Event_Name => events(:stepitup).name, :key => events(:stepitup).democracy_in_action_key, :supporter_KEY => 1)
    DemocracyInActionEvent.stubs(:find).returns(e)
    @request.host = sites(:stepitup).host
#    @request.session[:user] = s
  end

  def test_index
    login_as :quentin
#    DemocracyInActionSupporter.any_instance.expects(:events_attending).returns([])
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_show
    login_as :action_host
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
  end
end
