require File.dirname(__FILE__) + '/../test_helper'
require 'calendars_controller'

# Re-raise errors caught by the controller.
class CalendarsController; def rescue_action(e) raise e end; end

class CalendarsControllerTest < Test::Unit::TestCase
  fixtures :calendars, :sites, :events

  def setup
    @controller = CalendarsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_show
    test_for_each_calendar do |c|
      get :show, :permalink => c.permalink
      assert_response :success
    end
  end
end
