class HeartbeatController < ActionController::Base
  session :off
  def index
    render :text => 'OK', :layout => false
  end
end
