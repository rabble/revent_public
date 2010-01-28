require File.dirname(__FILE__) + '/../../test_helper'
require 'account/blogs_controller'

require 'mocha'

# Re-raise errors caught by the controller.
class Account::BlogsController; def rescue_action(e) raise e end; end

class Account::BlogsControllerTest < Test::Unit::TestCase
  def setup
    @controller = Account::BlogsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
