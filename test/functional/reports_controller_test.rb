require File.dirname(__FILE__) + '/../test_helper'
require 'reports_controller'

# Re-raise errors caught by the controller.
class ReportsController; def rescue_action(e) raise e end; end

class ReportsControllerTest < Test::Unit::TestCase
  fixtures :reports, :users, :roles, :roles_users, :sites, :calendars, :events

  def setup
    @controller = ReportsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # setup site/calendar and host
    @calendar   = calendars(:siu_nov)
    @site       = @calendar.site
    @request.host = @site.host
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_list
    login_as :quentin
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:reports)
  end

  def test_show
    get :show, :event_id => 3

    assert_response :success
    assert_template 'show'

    assert !assigns(:event).reports.empty?
    assert assigns(:event).reports.first.valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:report)
  end

  # getting hit by spam which embed in report hash
  def test_create
    post :create, {:report => {:embed => 'dummy'}}
    assert_response :redirect 
    post :create, {:report => {:honeypot => 'dummy'}}
    assert_response :redirect
  end

=begin
  def test_create
    num_reports = Report.count

    Akismet.any_instance.expects(:comment_check).returns(false)
    post :create, :report => { :event_id => 1, :text => 'hi' }, :press_links => [{:url => 'http://link_to.com', :text => 'title'}], :attachments => [], :user => {:first_name => 'test', :last_name => 'create', :email => 'create@create.com'}
    @report = Report.find(:all).last
    assert_equal @report.press_links.first.url, 'http://link_to.com'

    assert_response :success
    assert_template 'index'

    assert_equal num_reports + 1, Report.count
  end
=end
end
