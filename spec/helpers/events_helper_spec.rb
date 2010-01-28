require File.dirname(__FILE__) + '/../spec_helper.rb'

describe EventsHelper do
  it "should state click" do
    map = stub('map', :dom_id => 'map')
    helper.gmaps_state_click(map).should_not be_empty
  end
  it "should auto center and zoom" do
    map = stub('map', :markers => [])
    helper.gmaps_auto_center_and_zoom(map).should_not be_empty
  end
  it "should state centers" do
    helper.state_centers.should == EventsController::STATE_CENTERS
  end
  it "should event date range" do
    event = stub('event', :start? => true, :start => Date.new(2008, 1, 1), :end => Date.new(2008, 1, 2))
    helper.event_date_range(event).should_not be_empty
  end
end
